// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {NetworkConfigHelper} from "./NetworkConfigHelper.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast - "fake" txs w/ no gas cost
        // Get priceFeed value from the network config struct
        NetworkConfigHelper networks = new NetworkConfigHelper();
        address priceFeed = networks.activeConfig();

        // After startBroadcast - real txs costing real gas
        // Deploy FundMe contract using the network config's price feed
        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
