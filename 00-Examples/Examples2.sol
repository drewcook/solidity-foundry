// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

contract Examples2 {
    // Basics
    function helloWorld() public pure returns (string memory) {
        return "Hello World";
    }

    function getNum(uint256 _num) public pure returns (uint256) {
        return _num;
    }

    function getOne() public pure returns (uint256) {
        uint256 x = 1;
        return x;
    }

    function getBoolean() public pure returns (bool) {
        bool boolean = true;
        return boolean;
    }

    function getAddress() public pure returns (address) {
        address vbuterin = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        return vbuterin;
    }

    function useArrayForUint256(
        uint256[] calldata input
    ) public pure returns (uint256[] memory) {
        return input;
    }

    function booleanArray(
        bool[] calldata input
    ) public pure returns (bool[] memory) {
        return input;
    }

    function addressArray(
        address[] calldata input
    ) public pure returns (address[] memory) {
        return input;
    }

    function getFirstEl(uint256[] calldata nums) public pure returns (uint256) {
        return nums[0];
    }

    function getProductArray(
        uint256[] calldata nums
    ) public pure returns (uint256) {
        uint256 product = 1;
        for (uint256 i = 0; i < nums.length; i++) {
            product *= nums[i];
        }
        return product;
    }

    function getLastEl(uint256[4] calldata nums) public pure returns (uint256) {
        uint256 last = nums[3];
        return last;
    }

    function echo(string calldata input) public pure returns (string memory) {
        return input;
    }

    function sayHello(
        string calldata name
    ) public pure returns (string memory) {
        return string.concat("Hello, ", name);
    }

    function containsAThree(
        uint256[][] calldata nestedArr
    ) public pure returns (bool) {
        for (uint256 i = 0; i < nestedArr.length; i++) {
            for (uint256 j = 0; j < nestedArr[i].length; j++) {
                if (nestedArr[i][j] == 3) {
                    return true;
                }
            }
        }
        return false;
    }

    function getLastIdx(
        uint256[6][3] calldata nestedArr
    ) public pure returns (uint256) {
        return nestedArr[2][5];
    }

    // Storage
    uint256 internal x;

    function setX(uint256 _x) public {
        x = _x;
    }

    function getX() public view returns (uint256) {
        return x;
    }

    // Array
    uint256[] public myArray;

    function setMyArray(uint256[] calldata _arr) public {
        myArray = _arr;
    }

    function addToArray(uint256 _newItem) public {
        myArray.push(_newItem);
    }

    function removeFromArray() public {
        myArray.pop();
    }

    function getMyArrayLength() public view returns (uint256) {
        return myArray.length;
    }

    function getEntireArray() public view returns (uint256[] memory) {
        return myArray;
    }

    function popAndSwap(uint256 _idx) public {
        uint256 lastIdxVal = myArray[myArray.length - 1];
        myArray.pop(); // reduces length
        myArray[_idx] = lastIdxVal;
    }

    string public myName;

    function setMyName(string calldata _name) public {
        myName = _name;
    }

    // Mappings
    mapping(uint256 => uint256) public myMapping;
    mapping(uint256 => bool) public mapBool;
    mapping(uint256 => address) public mapAddress;

    function setMapValue(uint256 _key, uint256 _val) public {
        myMapping[_key] = _val;
    }

    function getMapValue(uint256 _key) public view returns (uint256) {
        return myMapping[_key];
    }

    // ERC20
    address public banker;

    // constructor(address _banker, string memory _name) {
    // banker = _banker;
    // myName = _name;
    // }

    mapping(address => uint256) public tokenBalances;

    function setTokenBalance(address owner, uint256 amount) public {
        // only allow banker to transact
        if (msg.sender == banker) {
            tokenBalances[owner] = amount;
        }
    }

    function transferTokensBanker(
        address sender,
        address receiver,
        uint256 amount
    ) public {
        // only allow banker to transact
        if (msg.sender == banker) {
            tokenBalances[sender] -= amount;
            tokenBalances[receiver] += amount;
        }
    }

    function transferMyTokens(address to, uint256 amount) public {
        tokenBalances[msg.sender] -= amount;
        tokenBalances[to] += amount;
    }

    // Nested Mapping
    mapping(uint256 => mapping(uint256 => uint256)) public nestedMap;

    function setNestedMapVal(
        uint256 _key1,
        uint256 _key2,
        uint256 _val
    ) public {
        nestedMap[_key1][_key2] = _val;
    }

    function getNestedMapVal(
        uint256 _key1,
        uint256 _key2
    ) public view returns (uint256) {
        return nestedMap[_key1][_key2];
    }

    // Global vars
    function whoAmI() public view returns (address) {
        address sender = msg.sender;
        return sender;
    }

    function whoAmIContract() public view returns (address) {
        return address(this);
    }

    // Revert
    function mustNotBeFive(uint256 n) public pure returns (uint256) {
        require(n != 5, "must not be five");
        return n * 2;
    }

    // Tuples
    function getTopScore() public pure returns (address, uint256) {
        return (0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 100);
    }

    function highestScoreIsOver1000() public pure returns (bool) {
        (address leader, uint256 score) = getTopScore();

        if (score > 1000) {
            return true;
        }

        return false;
    }
}
