// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Custom Errors
error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18; // $5
    address private immutable i_owner; // using i_ and s_ style guide from Chainlink

    // Private variables are more gas efficient
    AggregatorV3Interface private s_priceFeed;
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_donations;

    // Events
    event Fund(address depositor, uint256 amount);
    event Withdraw(address withdrawer, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // View / Pure functions (Getters)
    function getDonationAmount(address funder) external view returns (uint256) {
        return s_donations[funder];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    // Get the version of the price feed
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    // Take in ETH and keep track of the funder(s) and depositor
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Minimum deposit not met"
        );
        s_funders.push(msg.sender);
        s_donations[msg.sender] += msg.value;
        emit Fund(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        // Reset the donations and funders
        for (uint256 funderIdx = 0; funderIdx < s_funders.length; funderIdx++) {
            address funder = s_funders[funderIdx];
            s_donations[funder] = 0;
        }
        s_funders = new address[](0);

        // Transfer contract balance to owner
        uint256 withdrawAmount = address(this).balance;
        (bool ok, ) = payable(i_owner).call{value: withdrawAmount}("");
        require(ok, "Withdraw failed");

        emit Withdraw(i_owner, withdrawAmount);
    }

    function cheaperWithdraw() public onlyOwner {
        // Convert storage read to a memory read so that it only occurs once and not on each iteration
        uint256 fundersLength = s_funders.length;
        for (uint256 funderIdx = 0; funderIdx < fundersLength; funderIdx++) {
            address funder = s_funders[funderIdx];
            s_donations[funder] = 0;
        }

        // The rest of the calls are the same, no way to optimize them
        s_funders = new address[](0);
        uint256 withdrawAmount = address(this).balance;
        (bool ok, ) = payable(i_owner).call{value: withdrawAmount}("");
        require(ok, "Withdraw failed");
        emit Withdraw(i_owner, withdrawAmount);
    }
}
