// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Use a Chainlink data feed for ETH/USD - need Address and ABI to interact with it
// Sepolia Address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
// ABI - import the Chainlink AggregatorV3Interface interface
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Gets the current price of ETH in USD using the Chainlink data feed
    // To compare this price with a msg.value...
    // Convert the price data to have 18 decimal places and of the same types
    // We know it will have 8 decimal places, so need to get it to 18 by multiplying it against 1e10 (18-8=10) and convert to a uint256 with typecasting
    function getPrice() internal view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        ).latestRoundData();
        return uint256(price * 1e10);
    }

    // Converts a value to its converted value based off the price
    // 18 decimals           18 decimals           36 decimals
    // 1000000000000000000 * 1000000000000000000 = 1000000000000000000000000000000000000
    // Divide by 1e18 to convert it back down to only having 18 decimals (and multiple first, then divide)
    function getConversionRate(
        uint256 ethAmount
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() public view returns (uint256) {
        return
            AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306)
                .version();
    }
}
