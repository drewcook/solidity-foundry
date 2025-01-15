// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {DAO} from "../src/DAO.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {Timelock} from "../src/Timelock.sol";
import {Box} from "../src/Box.sol";

contract DAOTest is Test {
    DAO dao;
    GovernanceToken governanceToken;
    Timelock timelock;
    Box box;

    address[] proposers;
    address[] executors;

    address public USER = makeAddr("user");
    address public VOTER_1 = makeAddr("voter1");
    address public VOTER_2 = makeAddr("voter2");
    address public VOTER_3 = makeAddr("voter3");
    address public VOTER_4 = makeAddr("voter4");
    address public VOTER_5 = makeAddr("voter5");
    address public VOTER_6 = makeAddr("voter6");

    uint256 public constant MIN_EXECUTION_DELAY = 3600; // 1 hour - wait after a proposal passes to execute

    // for proposing
    address[] targets_1;
    bytes[] calldatas_1;
    uint256[] values_1;

    address[] targets_2;
    bytes[] calldatas_2;
    uint256[] values_2;

    function setUp() public {
        // Deploy the governance token, delegate to the user
        governanceToken = new GovernanceToken(USER);
        vm.startPrank(USER);
        governanceToken.delegate(USER);
        // Deploy the timelock, update to allow anyone to propose and execute
        timelock = new Timelock(MIN_EXECUTION_DELAY, proposers, executors);
        // Deploy the DAO, grant roles for the DAO and remove user as the admin of the timelock
        dao = new DAO(governanceToken, timelock);
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();
        timelock.grantRole(proposerRole, address(dao));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, USER);
        vm.stopPrank();
        // Deploy the box, timelock owns the DAO, DAO owns the timelock/dao, timelock has the ultimate say where stuff goes
        box = new Box(address(timelock));
        // box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceFailedProposal() public {
        // 1. Propose to the DAO
        uint256 valueToStore = 88;
        string memory description = "store 88 in the box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        targets_1.push(address(box));
        calldatas_1.push(encodedFunctionCall);
        values_1.push(0);
        uint256 proposalId = dao.propose(targets_1, values_1, calldatas_1, description);

        // 2. View the proposal state, ensure it's pending
        uint256 state1 = uint256(dao.state(proposalId));
        console.log("Proposal state: ", state1);
        assertEq(state1, 0); // Pending

        // 3. Mock blockchain updates to pass voting delay
        vm.warp(block.timestamp + dao.votingDelay() + 1);
        vm.roll(block.number + dao.votingDelay() + 1);
        uint256 state2 = uint256(dao.state(proposalId));
        console.log("Proposal state: ", state2);
        assertEq(state2, 1); // Active

        // 4. Cast votes
        string memory reasonFor = "DAOs are fun";
        string memory reasonAgainst = "DAOs are not fun";
        uint8 forVote = 1;
        uint8 againstVote = 0;
        vm.prank(VOTER_1);
        dao.castVoteWithReason(proposalId, forVote, reasonFor);
        vm.prank(VOTER_2);
        dao.castVoteWithReason(proposalId, againstVote, reasonAgainst);
        vm.prank(VOTER_3);
        dao.castVoteWithReason(proposalId, againstVote, reasonAgainst);

        // 5. Mock blockchain updates to pass voting period
        vm.warp(block.timestamp + dao.votingPeriod() + 1);
        vm.roll(block.number + dao.votingPeriod() + 1);

        // 6. Verify state is defeated
        uint256 state3 = uint256(dao.state(proposalId));
        console.log("Proposal state: ", state3);
        assertEq(state3, 3); // Defeated
    }

    function testGovernancePassedProposal() public {
        // 1. Propose to the DAO
        uint256 valueToStore = 42;
        string memory description = "store 42 in the box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        targets_2.push(address(box));
        calldatas_2.push(encodedFunctionCall);
        values_2.push(0);
        uint256 proposalId = dao.propose(targets_2, values_2, calldatas_2, description);

        // 2. View the proposal state, ensure it's pending
        uint256 state1 = uint256(dao.state(proposalId));
        console.log("Proposal state: ", state1);
        assertEq(state1, 0); // Pending

        // 3. Mock blockchain updates to pass voting delay
        vm.warp(block.timestamp + dao.votingDelay() + 1);
        vm.roll(block.number + dao.votingDelay() + 1);
        uint256 state2 = uint256(dao.state(proposalId));
        console.log("Proposal state: ", state2);
        assertEq(state2, 1); // Active

        // 4. Cast votes, need 4 to reach quorum since 100 total supply of gov tokens
        string memory reasonFor = "DAOs are super fun";
        uint8 forVote = 1;
        uint8 againstVote = 0;
        vm.prank(VOTER_1);
        dao.castVoteWithReason(proposalId, forVote, reasonFor);
        vm.prank(VOTER_2);
        dao.castVoteWithReason(proposalId, forVote, reasonFor);
        vm.prank(VOTER_3);
        dao.castVoteWithReason(proposalId, forVote, reasonFor);
        vm.prank(VOTER_4);
        dao.castVoteWithReason(proposalId, forVote, reasonFor);
        vm.prank(VOTER_5);
        dao.castVoteWithReason(proposalId, forVote, reasonFor);
        vm.prank(VOTER_6);
        dao.castVoteWithReason(proposalId, againstVote, reasonFor);

        // 5. Mock blockchain updates to pass voting period
        vm.warp(block.timestamp + dao.votingPeriod() + 1);
        vm.roll(block.number + dao.votingPeriod() + 1);

        // 6. Verify state is succeeded
        uint256 state3 = uint256(dao.state(proposalId));
        console.log("Proposal state: ", state3);
        assertEq(state3, 5); // Succeeded

        // 7. Queue the proposal
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        dao.queue(targets_2, values_2, calldatas_2, descriptionHash);

        // 8. Verify the state is queued
        uint256 state4 = uint256(dao.state(proposalId));
        console.log("Proposal state: ", state4);
        assertEq(state4, 6); // Queued

        // 9. Wait for the minimum execution delay
        vm.warp(block.timestamp + MIN_EXECUTION_DELAY + 1);
        vm.roll(block.number + MIN_EXECUTION_DELAY + 1);

        // 10. Execute the proposal
        dao.execute(targets_2, values_2, calldatas_2, descriptionHash);

        // 11.Verify the state is executed
        uint256 state5 = uint256(dao.state(proposalId));
        console.log("Proposal state: ", state5);
        assertEq(state5, 7); // Executed

        // 12. Verify the box has been updated!
        console.log("Box number: ", box.getNumber());
        assertEq(box.getNumber(), valueToStore);
    }
}
