// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*

    Ether is sent to contract:

          is msg.data empty?
              /   \
            yes   no
           /        \
      receive()?   fallback()
        /    \
      yes     no
      /        \
  receive()    fallback()

*/

contract FallbackExample {
    uint256 public result;

    // Used when no calldata is passed and no/wrong function is specified, can take in ETH
    receive() external payable {
        result = 1;
    }

    // Used when no/wrong function is specified but when non-empty calldata is passed
    fallback() external payable {
        result = 2;
    }
}
