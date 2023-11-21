// SPDX-License-Identifier: MIT

// Handler is going to narrow down the way functions are called on the target contract during stateful fuzzing tests
// 1. Only be able to deposit approved tokens for collateral (weth, wbtc) and more than zero
// 2. Only allow users to redeem the max amount they have in the system
// 3. Should only mint DSC if the amount is less than the collateral

pragma solidity ^0.8.19;

import {console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine engine;
    DecentralizedStablecoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    address[] depositors;

    uint256 public timesMintIsCalled; // ghost variable

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _engine, DecentralizedStablecoin _dsc) {
        engine = _engine;
        dsc = _dsc;
        address[] memory collateralTokens = engine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // Constraining major functions

    function mintDsc(uint256 _amountDscToMint, uint256 _addressSeed) public {
        // only pick a msg.sender that has deposited collateral
        if (depositors.length == 0) {
            return;
        }
        address sender = depositors[_addressSeed % depositors.length];
        // ensure only mint less than the collateral value in the system and more than zero
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(sender);
        int256 maxDscToMint = (int256(collateralValueInUsd) / 2) - int256(totalDscMinted);
        if (maxDscToMint < 0) {
            return;
        }
        uint256 amount = bound(_amountDscToMint, 0, uint256(maxDscToMint));
        if (amount == 0) {
            return;
        }
        // call it
        vm.startPrank(sender);
        engine.mintDsc(amount);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    function depositCollateral(uint256 _collateralSeed, uint256 _amountCollateral) public {
        // use seed to randomly pick from either weth or wbtc, i.e. supported tokens
        ERC20Mock collateral = _getCollateralFromSeed(_collateralSeed);
        // bound collateral amount to not be zero
        uint256 amountCollateral = bound(_amountCollateral, 1, MAX_DEPOSIT_SIZE);
        // mint some collateral so they can actually deposit it to have sufficient allowance
        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(engine), amountCollateral);
        // call it
        engine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        // note, will double push
        depositors.push(msg.sender);
    }

    function redeemCollateral(uint256 _collateralSeed, uint256 _amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(_collateralSeed);
        // bound to the max amount they have in the system, ignore when zero collateral
        uint256 userCollateral = engine.getCollateralBalanceOfUser(msg.sender, address(collateral));
        uint256 amountCollateral = bound(_amountCollateral, 0, userCollateral);
        if (amountCollateral == 0) {
            return;
        }
        // call it
        engine.redeemCollateral(address(collateral), amountCollateral);
    }

    // Helper functions

    function _getCollateralFromSeed(uint256 _seed) private view returns (ERC20Mock) {
        if (_seed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}
