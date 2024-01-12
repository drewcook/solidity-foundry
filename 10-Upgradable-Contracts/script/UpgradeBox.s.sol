// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {BoxV1} from "../src/BoxV1.sol";

contract UpgradeBox is Script {
    function run() external returns (address) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);

        // Deploy our new V2 implementation contract
        vm.startBroadcast();
        BoxV2 newBox = new BoxV2();
        vm.stopBroadcast();
        address proxy = upgradeBox(mostRecentDeployment, address(newBox));
        return proxy;
    }

    function upgradeBox(address _proxy, address _newImplementation) public returns (address) {
        vm.startBroadcast();
        // Call the UUPS upgrade logic on the old implementation contract
        BoxV1 proxy = BoxV1(_proxy);
        proxy.upgradeToAndCall(_newImplementation, ""); // Proxy contract now points to this new implementation address
        vm.stopBroadcast();
        return address(proxy);
    }
}
