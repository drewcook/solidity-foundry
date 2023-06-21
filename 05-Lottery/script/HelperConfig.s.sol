// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkTokenMock} from "../test/mocks/LinkTokenMock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 ticketPrice;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        // Use the right config for the right chain
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig()
        public
        pure
        returns (NetworkConfig memory config)
    {
        config = NetworkConfig({
            ticketPrice: 0.1 ether,
            interval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 3015,
            callbackGasLimit: 500000,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getOrCreateAnvilConfig()
        public
        returns (NetworkConfig memory config)
    {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            config = activeNetworkConfig;
        }

        // Mocks that are needed to be created for deployment
        // 1. VRF coordinator is needed
        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 Gwei
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        vm.stopBroadcast();
        // 2. LINK token is needed - use our own mock (snapshot LINK token contract written using latest Solidity version)
        LinkTokenMock linkToken = new LinkTokenMock();

        // Return our config using mocks
        config = NetworkConfig({
            ticketPrice: 0.1 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            linkToken: address(linkToken)
        });
    }
}
