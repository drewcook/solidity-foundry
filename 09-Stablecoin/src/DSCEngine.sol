// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DecentralizedStablecoin} from "./DecentralizedStablecoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Drew Cook
 * @notice This system is designed to be as minimal as possible and have the tokens maintain a 1 token = $1 peg.
 * @notice This stablecoin has the poroperties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmically Stable
 * @notice It is similar to DAI if DAI had no governance, no fees, and was only backed by wETH and wBTC.
 * @notice This contract is the core of the DSC System. It handles all the logic for mining and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is very loosly based on the MakerDAO DSS (DAI) system.
 * @notice Our DSC system should be "overcollateralized". At no point should the value of all collateral <= the $ backed value of all the DSC.
 */
contract DSCEngine is ReentrancyGuard {
    ////////////////////////
    /// Errors
    ////////////////////////

    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor();
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOkay();
    error DSCEngine__HealthFactorNotImproved();

    ////////////////////////
    /// State Variables
    ////////////////////////

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10; // magic number
    uint256 private constant PRECISION = 1e18; // magic number
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // magic number, 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10; // this means a 10% bonus
    uint256 private constant MIN_HEALTH_FACTOR = 1e10;

    // Only allow specific tokens to be used as collateral
    mapping(address token => address priceFeed) private s_priceFeeds; // "tokenToPriceFeed"
    // Keep track of user deposits
    mapping(address depositor => mapping(address token => uint256 amount)) private s_collateralDeposits; // "depositorToTokenAmounts"
    mapping(address minter => uint256 amountDscMinted) private s_DscMinted;

    address[] private s_collateralTokens;
    DecentralizedStablecoin private immutable i_dsc;

    ////////////////////////
    /// Events
    ////////////////////////

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    ////////////////////////
    /// Modifiers
    ////////////////////////

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address _tokenAddress) {
        if (s_priceFeeds[_tokenAddress] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    ////////////////////////
    /// Functions
    ////////////////////////

    constructor(address[] memory _tokenAddresses, address[] memory _priceFeedAddresses, address _dscAddress) {
        // Set up the price feeds
        if (_tokenAddresses.length != _priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        // Chainlink USD Price Feeds: ETH/USD, BTC/USD, MKR/USD, etc.
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            s_priceFeeds[_tokenAddresses[i]] = _priceFeedAddresses[i];
            s_collateralTokens.push(_tokenAddresses[i]);
        }

        // Set up the DSC token to work with (mint/burn)
        i_dsc = DecentralizedStablecoin(_dscAddress);
    }

    ////////////////////////
    /// External Functions
    ////////////////////////

    /*
     * @param _tokenCollateralAddress The address of the token to deposit as collateral
     * @param _amountCollateral The amount of collateral to deposity
     * @param _amountDscToMint The amount of DSC to mint
     * @notice This function will deposit your collateral and mint DSC in one transaction, to be used as a primary function of the protocol.
     */
    function depositCollateralAndMintDSC(
        address _tokenCollateralAddress,
        uint256 _amountCollateral,
        uint256 _amountDscToMint
    ) external {
        depositCollateral(_tokenCollateralAddress, _amountCollateral);
        mintDsc(_amountDscToMint);
    }

    /// @notice Follows CEI
    /// @param _tokenCollateralAddress The address of the collateral token used for the deposit
    /// @param _amountCollateral The amount of collateral to deposit
    function depositCollateral(address _tokenCollateralAddress, uint256 _amountCollateral)
        public
        moreThanZero(_amountCollateral)
        isAllowedToken(_tokenCollateralAddress)
        nonReentrant
    {
        // Internal record keeping
        s_collateralDeposits[msg.sender][_tokenCollateralAddress] += _amountCollateral;
        // Broadcast the user action
        emit CollateralDeposited(msg.sender, _tokenCollateralAddress, _amountCollateral);
        bool success = IERC20(_tokenCollateralAddress).transferFrom(msg.sender, address(this), _amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /*
     * @param _tokenCollateralAddress The address of the token to redeem from collateral
     * @param _amountCollateral The amount of collateral to redeem
     * @param _amountDscToBurn The amount of DSC to burn
     * @notice This function will redeem your collateral and burn DSC in one transaction, to be used as a primary function of the protocol.
     */
    function redeemCollateralForDSC(
        address _tokenCollateralAddress,
        uint256 _amountCollateral,
        uint256 _amountDscToBurn
    ) external {
        burnDsc(_amountDscToBurn);
        redeemCollateral(_tokenCollateralAddress, _amountCollateral);
        // redeemCollateral already checks health factor
    }

    /*
     * @notice In order to redeem collateral, a user's health factor should be >1 AFTER the collateral is pulled out.
     */
    function redeemCollateral(address _tokenCollateralAddress, uint256 _amountCollateral)
        public
        moreThanZero(_amountCollateral)
        nonReentrant
    {
        // redeem to the the address calling this function (self-redeem)
        _redeemCollateral(msg.sender, msg.sender, _tokenCollateralAddress, _amountCollateral);
        // check health factor
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /*
     * @notice followes CEI
     * @param _amountDscToMint The amount of decentralized stablecoin to mint
     * @notice the must have more collateral value than the minimum threshold
     */
    function mintDsc(uint256 _amountDscToMint) public moreThanZero(_amountDscToMint) nonReentrant {
        s_DscMinted[msg.sender] += _amountDscToMint;
        // if they minted too much (eg $150 DSC, $100 ETH)
        _revertIfHealthFactorIsBroken(msg.sender);
        // mint the DSC
        bool minted = i_dsc.mint(msg.sender, _amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    /*
     * @notice Allows a user to burn their DSC easily. This can be useful if a user has too much collateral, eg due to an increase in price, and want to prevent getting liquidated.
     * @notice They can, in effect, burn their DSC to reduce their collateralization ratio.
     * @notice Probably don't need to check health facter after burning, since it will always increase it in theory, but doing so as a redundant fail-safe
     */
    function burnDsc(uint256 _amount) public moreThanZero(_amount) {
        _burnDsc(_amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); // probably won't ever hit, remove during a gas audit
    }

    /*
     * @param _tokenCollateralAddress The ERC20 collateral address to liquidate from the user
     * @param _user The user who has broken the health factor. Their _healthFa ctor should be below MIN_HEALTH_FACTOR
     * @notice If the value of a user's collateral drops, allow a way for other users to liquidate their positions and reduce their undercollaterliazation, and ultimately maintain the health of the protocol (prevents users from losing way much more than what they borrowed).
     * @notice Should be called when a user's collateral price tanks.
     * @notice A user can be partially liquidated
     * @notice The liquidator gets a 10% bonus.
     * @notice The user calling this function is incentivized to make money, and the user being liquidated is punished for not maintaining their collateralization ratio, eg $120 ETH backing 100 DSC, the liquidator takes back $120 backing and burn off the $100 DSC, making a $20 profit.
    */
    function liquidate(address _tokenCollateralAddress, address _user, uint256 _debtToCover)
        external
        moreThanZero(_debtToCover)
        nonReentrant
    {
        // check health factor of the user is liquidatable
        uint256 startingUserHealthFactor = _healthFactor(_user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOkay();
        }
        // 1. Take their collateral (determine how much ETH to take based off given $ of debt to pay down)
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(_tokenCollateralAddress, _debtToCover);
        // 2. Give them a 10% bonus
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        // 3. Redeem to the liquidator
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        _redeemCollateral(_user, msg.sender, _tokenCollateralAddress, totalCollateralToRedeem);
        // 4. Burn the DSC "debt" from the caller liquidating on behalf of the user getting liquidated
        _burnDsc(_debtToCover, _user, msg.sender);
        // 5. Check health factors for both users
        uint256 endingUserHealthFactor = _healthFactor(_user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function calculateHealthFactor(uint256 _totalDscMinted, uint256 _collateralValueInUsd)
        external
        pure
        returns (uint256)
    {
        return _calculateHealthFactor(_totalDscMinted, _collateralValueInUsd);
    }

    //////////////////////////////////////
    /// Private & Internal View Functions
    //////////////////////////////////////

    /*
     * @dev Low-level internal function, do not call unless the function calling it is checking for health factors being broken
     */
    function _burnDsc(uint256 _amountDscToBurn, address _onBehalfOf, address _dscFrom) private {
        // internal accounting
        s_DscMinted[_onBehalfOf] -= _amountDscToBurn;
        // transfer to the engine
        bool success = i_dsc.transferFrom(_dscFrom, address(this), _amountDscToBurn);
        // This condition is hypothetically unreachable
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        // burn the token as the engine (owner of token contract)
        i_dsc.burn(_amountDscToBurn);
    }

    // Used to support liquidators in addition to anyone redeeming their own collateral
    function _redeemCollateral(address _from, address _to, address _tokenCollateralAddress, uint256 _amountCollateral)
        private
    {
        // internal accounting, rely on compiler to revert for underflow
        s_collateralDeposits[_from][_tokenCollateralAddress] -= _amountCollateral;
        emit CollateralRedeemed(_from, _to, _tokenCollateralAddress, _amountCollateral);
        // transfer collateral
        bool success = IERC20(_tokenCollateralAddress).transfer(_to, _amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function _getAccountInformation(address _user)
        internal
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DscMinted[_user];
        collateralValueInUsd = getAccountCollateralValue(_user);
    }

    /// @notice Returns how close to liquidation a user is. A user's position has a 50% liquidation threshold, meaning they must have double the amount of value in collateral than what they are borrowing.
    /// @notice If a user goes below 1, then they can get liquidated.
    /// @param {address} _user - the address of the account to check for
    /// @return Their health factor
    function _healthFactor(address _user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(_user);
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }

    // 1. Check health factor (do they have enough collateral?)
    // 2. Revert if they don't
    function _revertIfHealthFactorIsBroken(address _user) internal view {
        uint256 userHealthFactor = _healthFactor(_user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor();
        }
    }

    //////////////////////////////////////
    /// Pure / View Functions
    //////////////////////////////////////

    function getAccountInformation(address _user)
        external
        view
        returns (uint256 totalDscMinted, uint256 collateralValudInUsd)
    {
        (totalDscMinted, collateralValudInUsd) = _getAccountInformation(_user);
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getDsc() external view returns (address) {
        return address(i_dsc);
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getCollateralTokenPriceFeed(address _token) external view returns (address) {
        return s_priceFeeds[_token];
    }

    function getCollateralBalanceOfUser(address _user, address _token) external view returns (uint256) {
        return s_collateralDeposits[_user][_token];
    }

    function getAccountCollateralValue(address _user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            // get the amount they've deposited
            uint256 userDeposits = s_collateralDeposits[_user][token];
            // map it to the price to get the USD value
            totalCollateralValueInUsd += getUsdValue(token, userDeposits);
        }
    }

    function getHealthFactor(address _user) external view returns (uint256) {
        return _healthFactor(_user);
    }

    /*
     * @param _token The ERC20 token address
     * @param _usdAmountInWei The USD value amount in provided wei (1e18) format
        Get price of ETH (token)
        How much $/ETH per ETH ??
        $2000 per 1 ETH, $1000 = 0.5 ETH
     */
    function getTokenAmountFromUsd(address _token, uint256 _usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // $10e18 * 1e18) / ($2000e8 * 1e10)
        return (_usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    /*
     * @param _token The ERC20 token address
     * @param _amount The amount of the token to calculate the USD value of
     * @notice Gets the USD value for the provided token
     */
    function getUsdValue(address _token, uint256 _amount) public view returns (uint256 totalUsdValue) {
        // get price for the token
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // multiply it by the amount
        // ex. 1 ETH = $1000
        // The returned value from CL will be 1000 * 1e8 (eth/usd price feed has 8 decimals)
        totalUsdValue = (uint256(price) * ADDITIONAL_FEED_PRECISION) * _amount / PRECISION; // (1000 * 1e8 * (1e10)) * 1000 * 1e18
    }

    function _calculateHealthFactor(uint256 _totalDscMinted, uint256 _collateralValueInUsd)
        internal
        pure
        returns (uint256)
    {
        // If debt is zero, i.e. depositing lots of collateral but no dsc minted, will divide by zero and break
        if (_totalDscMinted == 0) return type(uint256).max;
        // get the ratio of these two values and in accordance with the liquidation threshold
        uint256 collateralAdjustedForThreshold = (_collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        // $1000 ETH * 50 = 50,000 / $100 DSC = ($500 / 100) > 1 (good)
        // $150 * 50 = 7500 / 100 = ($75/100) < 1 (not good)
        return (collateralAdjustedForThreshold * PRECISION) / _totalDscMinted;
    }
}
