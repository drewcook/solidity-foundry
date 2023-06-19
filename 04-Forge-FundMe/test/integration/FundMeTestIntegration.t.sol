// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract FundMeTestIntegration is Test {
    FundMe fundMe;
    address DEPOSITOR = makeAddr("depositor");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_AMOUNT = 0.1 ether;
    uint256 constant GAS_PRICE = 20 gwei;

    // Same setup as unit tests
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(DEPOSITOR, STARTING_BALANCE);
    }

    // The integration test:
    // A full suite of user interactions testing the functions of the contract as a whole
    function testUserCanFundInteractions() public {
        // Deposit
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));
        // Withdraw
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assertEq(
            address(fundMe).balance,
            0,
            "expect balance to be zero after depositing and withdrawing"
        );
    }
}
