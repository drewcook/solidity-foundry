// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

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
            linkToken,

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

    function testCantEnterWhenRaffleIsCalculating() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__StatusNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketPrice}();
    }

    ////////////////////////
    // checkUpkeep() tests
    ////////////////////////

    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testCheckUpkeepReturnsFalseIfNoBalance() external {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // no payment into it
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalsIfNotOpen() external {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); // puts state to CALCULATING
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTimePassed() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketPrice}();
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // no time warping
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueIfValidParameters()
        external
        raffleEnteredAndTimePassed
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    ////////////////////////
    // performUpkeep() tests
    ////////////////////////

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()
        external
        raffleEnteredAndTimePassed
    {
        raffle.performUpkeep(""); // should work if not revert
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() external {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep(""); // should revert with error and params
    }

    // What if we need to test using the output of an event?
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        external
        raffleEnteredAndTimePassed
    {
        // Act - capture emitted request id param from event
        vm.recordLogs();
        raffle.performUpkeep(""); // emits request id
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // Get request id out of the correct event within the logs (will be the second)
        bytes32 requestId = entries[1].topics[1]; // (0 topic is whole event)
        Raffle.RaffleState rState = raffle.getRaffleState();
        // Assert
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    ////////////////////////
    // fulfillRandomWords() tests
    ////////////////////////

    // Use fuzz testing and use requestId as the invariant
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) external raffleEnteredAndTimePassed {
        // Arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId, // shouldn't exist
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksWinnerResetsAndSendsMoney()
        external
        raffleEnteredAndTimePassed
    {
        // Arrange (add some more entrants)
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            // Enter new player
            address player = address(uint160(i));
            hoax(player, STARTING_BALANCE);
            raffle.enterRaffle{value: ticketPrice}();
        }
        uint256 prevTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = ticketPrice * (additionalEntrants + 1);

        // Act - capture request ID and pretend to be VRF to get random number & pick winner
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assert - check state was reset and winner was picked and paid
        assert(uint256(raffle.getRaffleState()) == 0); // should be open
        assert(raffle.getRecentWinner() != address(0)); // should be a winner
        assert(raffle.getLenghtOfPlayers() == 0);
        assert(raffle.getLastTimeStamp() > prevTimeStamp);
        assert(
            raffle.getRecentWinner().balance ==
                STARTING_BALANCE + prize - ticketPrice
        );
    }
}
