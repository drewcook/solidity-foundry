// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {CustomToken} from "../src/CustomToken.sol";

contract DeployCustomToken is Script {
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function run() external returns (CustomToken) {
        CustomToken token;
        vm.startBroadcast();
        token = new CustomToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return token;
    }
}
