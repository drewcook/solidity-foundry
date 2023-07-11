// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/*
	Order of operations:
	1. Users register paying the ticket price
	2. Chainlink Automation will continue to call performUpkeep() (check to see if we can pick a winner)
	3. performUpkeep() will call checkUpkeep() which will check our conditions if we can pick a winner
		4. If we cannot pick a winner, we revert the call
	5. If we can pick a winner, the VRF coordinator is called to fullfillRandomWords() to generate a random number
	6. The random number is generated in one call. A second call is made to run the callback of what to do with the random number, which is our override fullfillRandomWords() function
	7. The override fullfillRandomWords() function will use the random number to pick a index in our players array, transfers the contract balance to them, and resets the raffle state

*/

/// @title A simple raffle contract
/// @author Drew Cook
/// @notice This contract is for creating a simple raffle with a single winner
/// @dev Implements Chainlink VRFv2
contract Raffle is VRFConsumerBaseV2 {
    // Errors
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__StatusNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    // Type declarations
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    // State Variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint16 private constant NUM_WORDS = 1;

    uint256 private immutable i_ticketPrice;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;

    // Events
    event EnterRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 _ticketPrice,
        uint256 _interval,
        address _vrfCoordinator, // chain specific
        bytes32 _gasLane, // chain specific
        uint64 _subscriptionId, // subscription specific
        uint32 _callbackGasLimit // chain specific
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_ticketPrice = _ticketPrice;
        i_interval = _interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    // Ensure that participants buy their tickets with the ticket price
    function enterRaffle() external payable {
        // Check correct ticket price
        if (msg.value < i_ticketPrice) {
            revert Raffle__NotEnoughEthSent();
        }
        // Check correct status
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__StatusNotOpen();
        }
        // Update storage
        s_players.push(payable(msg.sender));
        // Events make migration easier
        emit EnterRaffle(msg.sender);
    }

    // Chainlink Automation - Upkeep callbacks
    /**
        @dev This is the function called by the Chainlink Automation node(s) to see if it's time to perform an upkeep. The upkeep will end up calling pickWinner().
        Requirements:
        1. The time interval has passed between raffle runs
        2. The raffle status is OPEN
        3. The contract has both players and an ETH balance
        4. (Implicit) The subscription is funded with LINK
    */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool raffleIsOpen = s_raffleState == RaffleState.OPEN;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timeHasPassed &&
            raffleIsOpen &&
            hasPlayers &&
            hasBalance);
        return (upkeepNeeded, "0x0");
    }

    // This is called via a Chainlink Automation subscription
    // Ensure no one can enter raffle while picking winner
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        // Update raffle status
        s_raffleState = RaffleState.CALCULATING;

        // Get a random number from Chainlink VRF (makes a request)
        // 1. Request the RNG
        // 2. Get the random number (callback, tx chainlink node sends back)
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
    }

    // Chainlink VRF Callback
    // CEI - Checks (requires), Effects (own contract), Interactions (other contracts)
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        // Checks - none

        // Use the random number to pick a random index in our players array
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];

        // Effects - update storage variables, and emit relevant events
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);

        // Interactions - transfer funds to the winner and keep track of latest winter
        (bool success, ) = s_recentWinner.call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    // View and Pure Functions

    function getTicketPrice() external view returns (uint256) {
        return i_ticketPrice;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 _indexOfPlayer) external view returns (address) {
        return s_players[_indexOfPlayer];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLenghtOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
