// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";

contract DeployAndUpgradeTest is Test {
    DeployBox public deployer;
    UpgradeBox public upgrader;
    address public OWNER = makeAddr("owner");

    address public proxy;

    function setUp() public {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();
        proxy = deployer.run(); // right now points to BoxV1
    }

    function testProxyStartsAsBoxV1() public {
        uint256 expectedVersion = 1;
        assertEq(expectedVersion, BoxV1(proxy).version());
    }

    function testDeploymentIsBoxV1() public {
        vm.expectRevert();
        BoxV2(proxy).setNumber(7);
    }

    function testUpgrades() public {
        // Deploy a BoxV2 contract
        BoxV2 boxV2 = new BoxV2();

        // Upgrade the proxy to point to the new BoxV2 contract (transfer ownership to test)
        vm.prank(BoxV1(proxy).owner());
        BoxV1(proxy).transferOwnership(msg.sender);
        upgrader.upgradeBox(proxy, address(boxV2));

        // Assert version
        uint256 expectedVersion = 2;
        assertEq(expectedVersion, BoxV2(proxy).version());

        // Assert setNumber
        BoxV2(proxy).setNumber(7);
        assertEq(7, BoxV2(proxy).getNumber());
    }
}
