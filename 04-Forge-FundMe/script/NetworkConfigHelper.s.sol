// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Deploying our own network configs
// 1. Deploy mocks when we are on local anvil chain and/or testing
// 2. Keep track of contract addresses across different chains
//    - price feeds, vrfs, gas price, etc
// Sepolia ETH/USD
// Mainnet ETH/USD

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

struct NetworkConfig {
    address priceFeed; // ETH/USD chainlink price feed address
}

contract NetworkConfigHelper is Script {
    // If we are on a local anvil chain, deploy mocks
    // Otherwise use the price feeds from the public network
    NetworkConfig public activeConfig;

    // Maintain readable code for magic numbers
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 137) {
            activeConfig = getPolygonConfig();
        } else if (block.chainid == 11155111) {
            activeConfig = getSepoliaEthConfig();
        } else if (block.chainid == 5) {
            activeConfig = getGoerliEthConfig();
        } else {
            activeConfig = getAnvilEthConfig();
        }
    }

    // Anvil (local)
    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check if we've set the price feed, if so return it to save on execution
        if (activeConfig.priceFeed != address(0)) {
            return activeConfig;
        }

        // 1. Deploy the mock(s)
        vm.startBroadcast();
        // mocking ETH/USD of 1 ETH = $2000
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        // 2. Use the mock addresse(s)
        NetworkConfig memory config = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return config;
    }

    // Polygon Mainnet
    function getPolygonConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            priceFeed: 0xF9680D99D6C9589e2a93a78A04A279e509205945
        });
        return config;
    }

    // Sepolia
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return config;
    }

    // Goerli
    function getGoerliEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            priceFeed: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        });
        return config;
    }
}
