// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title DecentralizedStablecoin
/// @author Drew Cook
/// @notice This stablecoin has the following properties:
/// - Collateral: Exogenous (ETH & BTC)
/// - Minting: Algorithmic
/// - Relative Stability: Pegged to USD
/// @notice This is the contract meant to be governed by the DSCEngine. This contract is just the ERC20 implementation of our stablecoin system
contract DecentralizedStablecoin is ERC20Burnable, Ownable {
    error DecentralizedStablecoin__MustBeMoreThanZero();
    error DecentralizedStablecoin__BurnAmountExceedsBalance();
    error DecntralizedStablecoin__NoZeroAddress();

    constructor() ERC20("DecntralizedStablecoin", "DSC") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStablecoin__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralizedStablecoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecntralizedStablecoin__NoZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStablecoin__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
