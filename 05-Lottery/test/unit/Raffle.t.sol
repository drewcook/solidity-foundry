// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

/**
	Tests todo:
	1. Write some deploy scripts
	2. Write some tests
		a. Work on local chain
		b. Work on forked testnet
		c. Work on forked mainnet
 */

contract TestRaffle is Test {
    // Storage variables
    Raffle raffle;
    HelperConfig helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    uint256 ticketPrice;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;

    // Events
    event EnterRaffle(address indexed player);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            ticketPrice,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            linkToken
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testInitialRaffleState() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    ////////////////////////
    // enterRaffle() tests
    ////////////////////////

    function testEnterRaffleWrongTicketPrice() external {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testEnterRaffleWrongState() external {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); // Will set state to RaffleState.CALCULATING

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__StatusNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketPrice}();
    }

    function testEnterRaffleRecordsPlayer() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketPrice}();
        assertEq(
            raffle.getPlayer(0),
            PLAYER,
            "Player should be added to storage variable"
        );
    }

    function testEnterRaffleEmitsEvent() external {
        vm.prank(PLAYER);
        // topic1, topic2, topic3, data (unindexed topics), emitter address
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnterRaffle(PLAYER);
        raffle.enterRaffle{value: ticketPrice}();
    }
}
