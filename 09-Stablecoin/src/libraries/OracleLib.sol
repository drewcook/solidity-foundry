// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Our system relies on price feeds from Chainlink. Each Chainlink Price Feed has a heartbeat. If the price becomes stale, either due to a skipped heartbeat or the price feed going down or offline, we want to pause our system.

/// @title OracleLib
/// @author Drew Cook (dco)
/// @notice This library is used to check the Chainlink Oracle for stale data. If a price is stale, the function will revert and render the DSCEngine unusable - this is by design.
/// @notice We want the DSCEngine to freeze if prices become stale. Because if you have a lot of TVL in the protocol, you're SOL.
library OracleLib {
    error OracleLib__StalePrice();

    uint256 private constant TIMEOUT = 3 hours; // 3 * 60 * 60 = 10800 seconds (longer than chainlink ETH/USD heartbeat which is 3600)

    function staleCheckLatestRoundData(AggregatorV3Interface _priceFeed)
        public
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        // Call the price feed to get latest round data
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            _priceFeed.latestRoundData();
        // Check if the price feed is stale
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > TIMEOUT) revert OracleLib__StalePrice();
        // Return round data
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
