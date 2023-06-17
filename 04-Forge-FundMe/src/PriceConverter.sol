// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Use a Chainlink data feed for ETH/USD - need Address and ABI to interact with it
// Sepolia Address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
// ABI - import the Chainlink AggregatorV3Interface interface
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Gets the current price from the price feed
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    // Converts a value to its converted value based off the price
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}
