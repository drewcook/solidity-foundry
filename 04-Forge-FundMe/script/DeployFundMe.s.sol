// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {NetworkConfigHelper} from "./NetworkConfigHelper.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast - fake txs
        NetworkConfigHelper networks = new NetworkConfigHelper();
        address priceFeedEthUsd = networks.activeConfig();

        // After startBroadcast - real txs costing real gas
        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeedEthUsd);
        vm.stopBroadcast();
        return fundMe;
    }
}
