// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Examples {
    function getEncoding(uint x) public pure returns (bytes memory) {
        return abi.encodeWithSignature("takeOneArg()", x);
    }

    function takeOneArg(uint256 x) public pure returns (bytes memory) {
        // we won't do anything with x
        return msg.data;
    }

    function encodeXY(uint256 x, uint256 y) public pure returns (bytes memory) {
        return abi.encode(x, y);
    }

    function getATuple(
        bytes memory encoding
    ) public pure returns (uint256, uint256) {
        (uint256 x, uint256 y) = abi.decode(encoding, (uint256, uint256));
        return (x, y);
    }

    function askTheMeaningOfLife(address source) public returns (uint256) {
        (bool ok, bytes memory data) = source.call(
            abi.encodeWithSignature("meaningOfLife()")
        );
        require(ok, "call failed");
        return abi.decode(data, (uint256));
    }

    function askTheMeaningOfLifeAdd(
        address source,
        uint256 x,
        uint256 y
    ) public returns (uint256) {
        (bool ok, bytes memory data) = source.call(
            abi.encodeWithSignature("add(uint256,uint256)", x, y)
        );
        require(ok, "call failed");
        uint256 sum = abi.decode(data, (uint256));
        return sum;
    }
}

contract Calc {
    function add(uint256 x, uint256 y) public pure returns (uint256) {
        return x + y;
    }
}

contract AllKnowing {
    function meaningOfLife() public pure returns (uint256) {
        return 32;
    }
}

contract TakeMoney {
    receive() external payable {}

    function viewBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract ForwardMoney {
    function payMe() public payable {}

    function viewBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sendMoney(address luckyAddress) public payable {
        uint256 myBalance = viewBalance();
        luckyAddress.call{value: myBalance}("");
    }
}

// Very wallet-like
contract SaveMoney {
    // Anyone can pay in
    receive() external payable {}

    function viewBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Only owner can withdraw
    function withdrawMoney() public payable {
        require(
            msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
            "not the first remix address (wallet owner)"
        );
        msg.sender.call{value: viewBalance()}("");
    }
}

contract PayableContract {
    receive() external payable {}

    function payMe() public payable {}

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyBalance() public view returns (uint256) {
        return msg.sender.balance;
    }

    function getTheirBalance(address them) public view returns (uint256) {
        return them.balance;
    }

    // More readable
    function moreThanOneEtherV1() public view returns (bool) {
        return msg.sender.balance > 1 ether;
    }

    // Less readable
    function moreThanOneEtherV2() public view returns (bool) {
        if (msg.sender.balance > 10 ** 18) {
            return true;
        }
        return false;
    }
}

contract SendMoney {
    // Can load up money on creation
    constructor() payable {}

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Send entire contract balance to another contract that has a payMe() function
    function sendMoney(address receiverContract) public payable {
        uint256 amount = getContractBalance();
        (bool ok, ) = receiverContract.call{value: amount}(
            abi.encodeWithSignature("payMe()")
        );
        require(ok, "transfer failed");
    }
}

contract WhatTimeIsIt {
    function whatBlock() public view returns (uint256) {
        return block.number;
    }

    function timestamp() public view returns (uint256) {
        return block.timestamp;
    }

    // Prevent calling to once every 24hr
    uint256 public lastCall;

    function hasCooldown() public {
        // uint256 day = 60 * 60 * 24;
        // require(block.timestamp > lastCall + day, "can only call once every 24hr");
        require(
            block.timestamp > lastCall + 1 days,
            "can only call once every 24hr"
        );
        lastCall = block.timestamp;
    }

    // Enforce ordering of operations
    uint256 private calledAt;

    function callMeFirst() external {
        calledAt = block.number;
    }

    function callMeSecond() external view {
        require(
            calledAt != 0 && block.number > calledAt,
            "callMeFirst() not called"
        );
    }
}

contract Parent {
    event Deposit(address indexed depositor, uint256 amount);

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function meaningOfLife() public pure virtual returns (uint256) {
        return 35;
    }
}

contract Parent2 {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    function favoriteNumber() public pure virtual returns (uint256) {
        return 2828;
    }

    function foo() internal pure virtual returns (string memory) {
        return "foo";
    }
}

contract Child is Parent, Parent2("TheBeatles") {
    function meaningOfLife() public pure override returns (uint256) {
        return 58;
    }

    function favoriteNumber() public pure override returns (uint256) {
        return 100;
    }

    // Overriding foo() and making itpublic
    // function foo() public pure override returns (string memory) {
    //     return super.foo();
    // }
}

// Better way to cross-call, V2
contract GetSumV1 {
    function getSum(
        address adder,
        uint256 x,
        uint256 y
    ) public returns (uint256) {
        (bool ok, bytes memory data) = adder.call(
            abi.encodeWithSignature("add(uint256,uint256)", x, y)
        );
        require(ok, "call failed");
        uint256 sum = abi.decode(data, (uint256));
        return sum;
    }
}

// V2
interface IAdder {
    function add(uint256, uint256) external pure returns (uint256);
}

contract GetSumV2 {
    function getSum(
        IAdder adder,
        uint256 x,
        uint256 y
    ) public pure returns (uint256) {
        return adder.add(x, y);
    }
}

contract Adder {
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract HoldFunds is Ownable {
    receive() external payable {}

    function withdrawFunds() public onlyOwner {
        (bool ok, ) = msg.sender.call{value: address(this).balance}("");
        require(ok, "transfer failed");
    }
}

contract TicketStand {
    uint256 public constant TICKET_PRICE = 0.01 ether;

    struct Ticket {
        string name;
        uint256 numberOfTickets;
    }

    mapping(address => Ticket) public tickets;

    function buyTicket(string memory _name, uint256 _amount) public payable {
        require(
            msg.value == _amount * TICKET_PRICE,
            "Wrong amount of ether sent"
        );
        require(_amount <= 10, "Max limit exceeded");
        require(
            tickets[msg.sender].numberOfTickets + _amount <= 10,
            "Max limit reached"
        );

        tickets[msg.sender].name = _name;
        tickets[msg.sender].numberOfTickets += _amount;
    }

    function displayTickets(
        address _holder
    ) public view returns (Ticket memory) {
        return tickets[_holder];
    }
}
