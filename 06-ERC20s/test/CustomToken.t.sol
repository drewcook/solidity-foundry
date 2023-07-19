// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployCustomToken} from "../script/DeployCustomToken.s.sol";
import {CustomToken} from "../src/CustomToken.sol";

contract CustomTokenTest is Test {
    CustomToken public token;
    DeployCustomToken public deployer;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployCustomToken();
        token = deployer.run();

        vm.prank(address(msg.sender));
        token.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public {
        assertEq(STARTING_BALANCE, token.balanceOf(bob));
    }

    function testAllowanceSuccess() public {
        uint256 initialAllowance = 100 ether;

        // Bab approves Alice to spend his tokens; Alice transfers to herself
        vm.prank(bob);
        token.approve(alice, initialAllowance);

        uint256 transferAmount = 50 ether;

        vm.prank(alice);
        token.transferFrom(bob, alice, transferAmount);

        assertEq(token.balanceOf(alice), transferAmount);
        assertEq(token.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    // TODO: You can use AI to help write more tests and fill in coverage, since ChatGPT does it fairly well
}
