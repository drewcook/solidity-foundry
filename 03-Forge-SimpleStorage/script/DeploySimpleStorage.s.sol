// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimpleStorage is Script {
    function run() external returns (SimpleStorage) {
        // Start broadcasting to the VM, every tx after this will be submitted to the RPC
        vm.startBroadcast();

        // Create an instance of the contract
        SimpleStorage simpleStorage = new SimpleStorage();

        // End broadcasting to the VM
        vm.stopBroadcast();

        return simpleStorage;
    }
}
