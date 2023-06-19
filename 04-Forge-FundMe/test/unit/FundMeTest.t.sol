// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

// Custom errors
error FundMe__NotOwner();

// Future features:
// - the contract should allow the owner to change the price feed
// Test cases:
// - storage varaibles and constants starting values
// - sending less than $5 worth of ETH should revert
// - sending $5 worth of ETH or more should work
// - the contract should keep track of the ETH balance
// - the contract should keep track of the funders
// - the contract should keep track of the ETH balance of each funder
// - the contract should revert if withdraw is not called by the owner
// - the contract should allow the owner to withdraw the ETH
// - the contract should reset the funders and donations after the owner withdraws
// - the contract should emit events when funded and when withdrawn
contract FundMeTest is Test {
    // Events
    event Fund(address depositor, uint256 amount);
    event Withdraw(address withdrawer, uint256 amount);

    // Common used vars
    FundMe fundMe;
    address DEPOSITOR = makeAddr("depositor");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_AMOUNT = 0.1 ether;
    uint256 constant GAS_PRICE = 20 gwei;

    // Modifiers - perform common operations for test setup
    modifier funded() {
        // Pre-conditions
        vm.prank(DEPOSITOR);
        fundMe.fund{value: SEND_AMOUNT}();
        _;
    }

    // Set up - runs before each test function
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // fund our depositor
        vm.deal(DEPOSITOR, STARTING_BALANCE);
    }

    function testMinimumDepositIsFive() public {
        assertEq(
            fundMe.MINIMUM_USD(),
            5e18,
            "expect a minimum deposit of 5 USD"
        );
    }

    function testOwnerIsMsgSender() public {
        assertEq(
            fundMe.getOwner(),
            msg.sender,
            "expect owner to be this contract"
        );
    }

    function testPriceFeedVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4, "expect the version to be 4");
    }

    function testDepositInvalidAmount() public {
        uint256 invalidAmount = 1e9; // 1 gWei < 5 USD
        vm.expectRevert("Minimum deposit not met");
        vm.prank(DEPOSITOR);
        fundMe.fund{value: invalidAmount}();
    }

    function testDepositUpdatesFundersList() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, DEPOSITOR, "should store the funder");
    }

    function testDepositUpdatesDonationAmountsPerFunder() public funded {
        uint256 donationAmount = fundMe.getDonationAmount(DEPOSITOR);
        assertEq(donationAmount, SEND_AMOUNT, "should store the donation");
    }

    function testDepositTotalBalanceIncreases() public payable funded {
        assertEq(
            address(fundMe).balance,
            SEND_AMOUNT,
            "should have added the deposit to total balance"
        );
    }

    // function testDepositEmitsEvent() public payable {
    //     vm.expectEmit();
    //     emit Fund(DEPOSITOR, SEND_AMOUNT);
    //     vm.deal(DEPOSITOR, SEND_AMOUNT);
    //     vm.prank(DEPOSITOR);
    //     fundMe.fund{value: SEND_AMOUNT}();
    // }

    function testWithdrawNonOwner() public funded {
        vm.prank(DEPOSITOR);
        vm.expectRevert(abi.encodeWithSelector(FundMe__NotOwner.selector));
        fundMe.withdraw();
    }

    function testWithdrawSingleDeposit() public funded {
        // Arrange
        uint256 ownerBalance_before = fundMe.getOwner().balance;
        uint256 contractBalance_before = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // Assert
        uint256 ownerBalance_after = fundMe.getOwner().balance;
        uint256 contractBalance_after = address(fundMe).balance;
        assertEq(
            ownerBalance_after,
            ownerBalance_before + contractBalance_before,
            "should have transferred the contract balance to the owner"
        );
        assertEq(
            contractBalance_after,
            0,
            "should have emptied the contract balance"
        );
    }

    function testWithdrawMultipleDeposits() public funded {
        // Arrange
        // Loop through and make multiple deposits from different addresses
        uint160 depositors = 10;
        uint160 startingIdx = 1;
        for (uint160 idx = startingIdx; idx < depositors; idx++) {
            address depositor = address(idx);
            hoax(depositor, SEND_AMOUNT);
            fundMe.fund{value: SEND_AMOUNT}();
        }
        uint256 ownerBalance_before = fundMe.getOwner().balance;
        uint256 contractBalance_before = address(fundMe).balance;

        // Anvil builds use zero as the gas price by default, but we can set it also to test against, since real networks will have a gas price, and we can debug how much gas being used for each call by performing some simple checks and math.
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        // vm.prank(fundMe.getOwner());
        // fundMe.withdraw();
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); // should have spent gas here

        // Assert
        uint256 ownerBalance_after = fundMe.getOwner().balance;
        uint256 contractBalance_after = address(fundMe).balance;
        assertEq(
            ownerBalance_after,
            ownerBalance_before + contractBalance_before,
            "should have transferred the contract balance to the owner"
        );
        assertEq(
            contractBalance_after,
            0,
            "should have emptied the contract balance"
        );
    }

    // For comparing gas gosts between the different withdraw functions
    function testWithdrawMultipleDepositsCheaper() public funded {
        // Arrange
        // Loop through and make multiple deposits from different addresses
        uint160 depositors = 10;
        uint160 startingIdx = 1;
        for (uint160 idx = startingIdx; idx < depositors; idx++) {
            address depositor = address(idx);
            hoax(depositor, SEND_AMOUNT);
            fundMe.fund{value: SEND_AMOUNT}();
        }
        uint256 ownerBalance_before = fundMe.getOwner().balance;
        uint256 contractBalance_before = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // Assert
        uint256 ownerBalance_after = fundMe.getOwner().balance;
        uint256 contractBalance_after = address(fundMe).balance;
        assertEq(
            ownerBalance_after,
            ownerBalance_before + contractBalance_before,
            "should have transferred the contract balance to the owner"
        );
        assertEq(
            contractBalance_after,
            0,
            "should have emptied the contract balance"
        );
    }
}
