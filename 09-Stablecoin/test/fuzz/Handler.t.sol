// SPDX-License-Identifier: MIT

// Handler is going to narrow down the way functions are called on the target contract during stateful fuzzing tests
// 1. Only call redeemCollateral when there is collateral deposited

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine engine;
    DecentralizedStablecoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _engine, DecentralizedStablecoin _dsc) {
        engine = _engine;
        dsc = _dsc;
        address[] memory collateralTokens = engine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // redeem collateral
    function depositCollateral(uint256 _collateralSeed, uint256 _amountCollateral) public {
        // use seed to randomly pick from either weth or wbtc, i.e. supported tokens
        ERC20Mock collateral = _getCollateralFromSeed(_collateralSeed);
        // bound collateral amount to not be zero
        uint256 amountCollateral = bound(_amountCollateral, 1, MAX_DEPOSIT_SIZE);
        // mint some collateral so they can actually deposit it to have sufficient allowance
        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(engine), amountCollateral);
        engine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    // Helper functions
    function _getCollateralFromSeed(uint256 _seed) private view returns (ERC20Mock) {
        if (_seed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}
