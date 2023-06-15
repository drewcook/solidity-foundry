// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SimpleStorage} from "./SimpleStorage.sol";

// Inheritance
contract AddFiveStorage is SimpleStorage {
    // Add five to everyone's favorite number, overriding the inherited, virtuaL function 'store'
    function store(uint256 _favoriteNumber) public override {
        myFavoriteNumber = _favoriteNumber + 5;
    }
}
