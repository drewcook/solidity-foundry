// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleStorage {
    uint256 myFavoriteNumber;

    // uint256[] listOfFavoriteNumbers;
    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    Person[] public listOfPeople;

    mapping(string => uint256) public nameToFavoriteNumber;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        listOfPeople.push(Person(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // Make this overridable using 'virtual' keyword
    function store(uint256 _favoriteNumber) public virtual {
        myFavoriteNumber = _favoriteNumber;
    }

    function favorite() public view returns (uint256) {
        return myFavoriteNumber;
    }
}
