// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ManualmToken {
    mapping(address => uint256) s_balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function name() public pure returns (string memory) {
        return "Manual Token";
    }

    function symbol() public pure returns (string memory) {
        return "MANUAL";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return 100 ether; // 100000000000000000000
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return s_balances[_owner];
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 previousBalances = balanceOf(msg.sender) + balanceOf(_to);
        s_balances[msg.sender] -= _value;
        s_balances[_to] += _value;
        require(previousBalances == balanceOf(msg.sender) + balanceOf(_to));
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // function transferFrom(
    //     address _from,
    //     address _to,
    //     uint256 _value
    // ) public returns (bool success) {}

    // function approve(
    //     address _spender,
    //     uint256 _value
    // ) public returns (bool success) {}

    // function allowance(
    //     address _owner,
    //     address _spender
    // ) public view returns (uint256 remaining) {}
}
