// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Custom Errors
error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18; // $5
    address public immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    address[] public s_funders;
    mapping(address funder => uint256 amountFunded) public s_donations;

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    event Fund(address depositor, uint256 amount);
    event Withdraw(address withdrawer, uint256 amount);

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Action not permitted");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // Fallback/recieve functions - if someone accidentily sends ETH without calling fund() function, auto-route them
    // This adds business logic in around arbitrarily someone sending money (i.e. Send on MetaMask, which doesn't call any particular function)
    // In this case, use the business logic on adding them in as a new funder and their s_donations balance
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    // Take in ETH and keep track of the funder
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Minimum deposit not met"
        );
        s_funders.push(msg.sender);
        s_donations[msg.sender] += msg.value;
        emit Fund(msg.sender, msg.value);
    }

    // Withdraw the funds to the owner
    // Reset the values for each depositor
    function withdraw() public onlyOwner {
        // Reset for each funder on their amount donated
        // (start idx, end idx, incrementer)
        for (uint256 funderIdx = 0; funderIdx < s_funders.length; funderIdx++) {
            address funder = s_funders[funderIdx];
            s_donations[funder] = 0;
        }

        // Clear out the s_funders array by resetting it to a brand new instance
        s_funders = new address[](0);

        // Withdraw out and transfer to owner
        uint256 withdrawAmount = address(this).balance;

        // we could use transfer()
        // payable(msg.sender).transfer(withdrawAmount);

        // or send()
        // bool success = payable(msg.sender).send(withdrawAmount);
        // require(success, "Send failed");

        // but it is best practice to use call{value: x}("")
        (bool ok, ) = payable(i_owner).call{value: withdrawAmount}("");
        require(ok, "Withdraw failed");

        emit Withdraw(i_owner, withdrawAmount);
    }
}
