// SPDX-License-Identifier: MIT

// Contains all the invariants (aka properties)

/*
	What are the invariants?
	1. The total supply of DSC should be less than the total value of collateral
	2. Getter view functions should never revert <- evergreen invariant
*/

pragma solidity ^0.8.19;

import {console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract Invariants is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine engine;
    DecentralizedStablecoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();
        // targetContract(address(engine));
        handler = new Handler(engine, dsc);
        // Set up the target contract
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        // get the value of all the collateral in protocol
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(engine));
        uint256 totalBtcDeposited = IERC20(wbtc).balanceOf(address(engine));
        uint256 wethValue = engine.getUsdValue(weth, totalWethDeposited);
        uint256 btcValue = engine.getUsdValue(wbtc, totalBtcDeposited);

        // console.log("weth value", wethValue);
        // console.log("btc value", btcValue);
        // console.log("total supply", totalSupply);
        // console.log("mint called", handler.timesMintIsCalled());

        // compare it to all debt (dsc)
        assert(wethValue + btcValue >= totalSupply);
    }

    // note: always include this invariant regardless of the contract
    function invariant_gettersShouldNotRevert() public view {
        engine.getAdditionalFeedPrecision();
        engine.getPrecision();
        engine.getLiquidationThreshold();
        engine.getLiquidationPrecision();
        engine.getLiquidationBonus();
        engine.getMinHealthFactor();
        engine.getDsc();
        engine.getCollateralTokens();
        engine.getCollateralTokenPriceFeed(weth);
        engine.getCollateralTokenPriceFeed(wbtc);
    }
}
