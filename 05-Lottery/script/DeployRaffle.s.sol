// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../script/Interactions.s.sol";

/**
    This deploy script will deploy a Raffle contract and wire it up to a Chainlink VRF subscription.
    It will attempt to use values provided in a network config for existing subscriptions.
    It will automate setting up a new subscription and funding it with LINK if it doesn't exist.
    All of thise without ever having to go into the Chainlink dapp UI.
 */
contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        // Get config values
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 ticketPrice,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address linkToken,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        // 1. Create a subscription if we don't have one defined in our config already
        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator,
                deployerKey
            );
            // ...And fund it with some LINK
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                linkToken,
                deployerKey
            );
        }

        // 2. Deploy Raffle contract using config values
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            ticketPrice,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        // 3. Regardless if using an existing subscription or not, wire up our Raffle contract as a consumer to the subscription
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            vrfCoordinator,
            subscriptionId,
            address(raffle),
            deployerKey
        );

        // 4. (Optionally) Add in a new upkeep to Chainlink automation, but for testing we act as the upkeeper

        // Return the instance
        return (raffle, helperConfig);
    }
}
