// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeMathTester {
    uint8 public bigNumber = 255; // unchecked

    function add() public {
        // unchecked is a gas-optimizing technique
        // however, this should only ever be used when it's known for certain that overflows/underflows will not occur in the math
        unchecked {
            bigNumber += 1;
        }
    }
}
