// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkTokenMock} from "../test/mocks/LinkTokenMock.sol";

// Create a Chainlink VRF subscription
contract CreateSubscription is Script {
    function run() external returns (uint64) {
        return createSubscriptionFromConfig();
    }

    function createSubscriptionFromConfig() internal returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , , ) = helperConfig
            .activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64) {
        console.log(
            "Created a subscription for given VRF Coordinator on ChainID: ",
            block.chainid
        );

        // Call the mock and create the subscription
        vm.startBroadcast();
        uint64 subscriptionId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log("Subscription ID: ", subscriptionId);
        console.log("Please update your subscriptionId in HelperConfig.s.sol");

        return subscriptionId;
    }
}

// Need the right
contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function run() external {
        fundSubscriptionFromConfig();
    }

    function fundSubscriptionFromConfig() internal {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            address linkToken,

        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subscriptionId,
        address linkToken
    ) public {
        // Run the same actions that the frontend would do on https://vrf.chain.link/sepolia/new
        console.log("Funding subscriptionID: ", subscriptionId);
        console.log("Using VRFCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        // If on anvil, use mock function signature
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            console.log(LinkTokenMock(linkToken).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkTokenMock(linkToken).balanceOf(address(this)));
            console.log(address(this));

            // Call the real VRFCoordinator on Sepolia using the real token
            vm.startBroadcast();
            LinkTokenMock(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }
}

// Need our deployed Raffle contract address to tell Chainlink to use it as a consumer of the subscription
contract AddConsumer is Script {
    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerFromConfig(raffle);
    }

    function addConsumerFromConfig(address raffle) internal {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();
        addConsumer(vrfCoordinator, subscriptionId, raffle, deployerKey);
    }

    function addConsumer(
        address vrfCoordinator,
        uint64 subscriptionId,
        address raffle,
        uint256 deployerKey
    ) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("Using VRFCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        // Call the underlying addConsumer() on the coordinator to add the instance of Raffle as a consumer
        // Pass in the private key for the subscription ID owner
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            raffle
        );
        vm.stopBroadcast();
    }
}
