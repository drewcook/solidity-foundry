// Build a crowdsourcing contract
// Accept deposit values from other users (use an oracle)
// Enforce deposits meet a minimum USD value
// Allow owner to withdraw funds

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

// Create custom errors and replace require() with rever Error() statments for gas optimizations
error NotOwner();

// Deployment costs:
// 729583 - not using constant/immutable
// 708884 - using constant
// 706710 - using immutable
// 686411 - using both
contract FundMe {
    // Apply all PriceConverter libary methods to any data of type uint256
    using PriceConverter for uint256;

    // Use constant/immutable for gas optimization deploying contract and reading these storage variables
    uint256 public constant MINIMUM_USD = 5e18; // or 5 * 1e18 (5 USD minimum)
    address public immutable _owner;

    address[] public funders;
    mapping(address funder => uint256 amountFunded) public donations;

    constructor() {
        _owner = msg.sender;
    }

    event Fund(address depositor, uint256 amount);
    event Withdraw(address withdrawer, uint256 amount);

    modifier onlyOwner() {
        // require(msg.sender == _owner, "Action not permitted");
        if (msg.sender != _owner) {
            revert NotOwner();
        }
        _;
    }

    // Fallback/recieve functions - if someone accidentily sends ETH without calling fund() function, auto-route them
    // This adds business logic in around arbitrarily someone sending money (i.e. Send on MetaMask, which doesn't call any particular function)
    // In this case, use the business logic on adding them in as a new funder and their donations balance
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // Take in ETH and keep track of the funder
    function fund() public payable {
        require(
            msg.value.getConversionRate() >= MINIMUM_USD,
            "Minimum deposit not met"
        );
        funders.push(msg.sender);
        donations[msg.sender] += msg.value;
        emit Fund(msg.sender, msg.value);
    }

    // Withdraw the funds to the owner
    // Reset the values for each depositor
    function withdraw() public onlyOwner {
        // Reset for each funder on their amount donated
        // (start idx, end idx, incrementer)
        for (uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++) {
            address funder = funders[funderIdx];
            donations[funder] = 0;
        }

        // Clear out the funders array by resetting it to a brand new instance
        funders = new address[](0);

        // Withdraw out and transfer to owner
        uint256 withdrawAmount = address(this).balance;

        // we could use transfer()
        // payable(msg.sender).transfer(withdrawAmount);

        // or send()
        // bool success = payable(msg.sender).send(withdrawAmount);
        // require(success, "Send failed");

        // but it is best practice to use call{value: x}("")
        (bool ok, ) = payable(_owner).call{value: withdrawAmount}("");
        require(ok, "Withdraw failed");

        emit Withdraw(_owner, withdrawAmount);
    }
}
