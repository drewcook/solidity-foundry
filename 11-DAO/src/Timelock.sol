// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    constructor(
        uint256 minDelay, // how long you have to wait before executing a proposal
        address[] memory proposers, // a list of addresses that can propose, we'll allow all addresses
        address[] memory executors // a list of addresses that can execute, we'll allow all addresses
    )
        // We will move the admin to be the DAO contract
        TimelockController(minDelay, proposers, executors, msg.sender)
    {}
}
