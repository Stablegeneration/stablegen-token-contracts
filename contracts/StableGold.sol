// SPDX-License-Identifier: MIT

//  ███████╗████████╗ █████╗ ██████╗ ██╗     ███████╗ ██████╗ ███████╗███╗   ██╗
//  ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝ ██╔════╝████╗  ██║
//  ███████╗   ██║   ███████║██████╔╝██║     █████╗  ██║  ███╗█████╗  ██╔██╗ ██║
//  ╚════██║   ██║   ██╔══██║██╔══██╗██║     ██╔══╝  ██║   ██║██╔══╝  ██║╚██╗██║
//  ███████║   ██║   ██║  ██║██████╔╝███████╗███████╗╚██████╔╝███████╗██║ ╚████║
//  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝

/**
 * @title StableGen - StableGold
 * @notice Gold-backed ERC20 token with oracle pricing, role-base access control, redemption options, on-chain buyback, cross-chain support, and compliance features.
 * @author StableGen Dev Team
 * @date 18-Aug-2026
 * @version 2.17.4
 * @custom:security-contact dev@stablegen.com
 */

pragma solidity ^0.8.25;

import "./IDataFeed.sol";
import "./AggregatorV3Interface.sol";
import "./IERC7802.sol";
import "./EIP3009.sol";
import "./SignatureChecker.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

using SafeERC20 for IERC20;

/**
 * @title StableGold - STBG Smart Contract
 * @dev Main contract implementation for a gold-backed ERC20 token.
 * Combines ERC20 functionality with oracle pricing, role-based access control,
 * compliance features (KYC, freezing), and cross-chain capabilities.
 */

contract StableGold is ERC20, Ownable, ERC20Burnable, IERC7802, EIP3009 {

    // =============================================================
    // State Variables
    // =============================================================

    /// @notice Maximum token supply when proof-of-reserve is disabled.
    /// @dev When `proofOfReserveEnabled` is true, minting is capped by the reserve feed instead.
    uint256 public maxSupply;

    /// @notice Purchase premium applied on top of spot gold price, in basis points (100 = 1%).
    uint256 public premium;

    /// @notice Fee deducted from spot price during on-chain buyback, in basis points (100 = 1%).
    uint256 public onchainBuyBackFee;

    /// @notice Amount minted to the deployer at construction.
    uint256 public premintSupply;

    /// @notice Destination address for OTC buyback redemptions (`redeem` with `_opt = 2`).
    address public buyBackAddress;

    /// @notice Returns whether an address has the admin role.
    mapping (address => bool) public admin;

    /// @notice Compliance controls.
    mapping (address => bool) public authority;
    mapping (address => bool) public custody;
    mapping (address => bool) public freezeList;
    mapping (address => bool) public kycStatus;
    mapping (address => bool) public minter;
    mapping (address => uint256) public onChainBBLimit;
    mapping (address => uint256) public onChainBBSpending;

    /// @notice Tracks the used status of authorizations for each address and nonce.
    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;

    /// @notice When true, most user-facing functions are blocked.
    bool public pause;

    /// @notice When true, physical redemption (`redeem` with `_opt = 1`) is enabled.
    bool public redeemStatus;

    /// @notice Chainlink-compatible oracle used for gold spot pricing.
    IDataFeed public priceFeed;

    /// @notice Returns whether a stablecoin is accepted for `buy` and `onchainBuyBack`.
    mapping (address => bool) public acceptedTokens;

    /// @notice When true, redeemed tokens are burned; when false, sent to the dead address.
    bool public burnRedeem;

    /// @notice When false, only KYC-approved custody addresses may call `buy`.
    bool public saleStatus;

    /// @notice When true, OTC buyback via `redeem` with `_opt = 2` is enabled.
    bool public buyBackStatus;

    /// @notice When true, `onchainBuyBack` is enabled.
    bool public onchainbuyBackStatus;

    /// @notice When true, EIP-3009 signed transfer functions are enabled.
    bool public enableSignedTxs;
    
    /// @notice When true, cross-chain mint and burn via the token bridge are enabled.
    bool public crossChainStatus;

    /// @notice Maximum age (seconds) allowed for gold price feed data before it is rejected.
    uint256 public dataFeedHeartbeat;

    /// @notice Minimum StableGold amount allowed per `redeem` call.
    uint256 public minAmountforRedeem;

    /// @notice Maximum StableGold amount allowed per `redeem` call.
    uint256 public maxAmountforRedeem;

    /// @notice Premium fees collected from `buy`, indexed by stablecoin address.
    mapping (address => uint256) public collectedPremiums;

    /// @notice Buyback fees collected from `onchainBuyBack`, indexed by stablecoin address.
    mapping (address => uint256) public collectedBBFees;

    /// @notice Maximum age (seconds) allowed for proof-of-reserve feed data.
    uint256 public chainReserveHeartbeat;

    /// @notice Chainlink-compatible oracle for on-chain proof of reserves.
    address public chainReserveFeed;

    /// @notice When true, minting is capped by the reserve feed instead of `maxSupply`.
    bool public proofOfReserveEnabled;

    /// @notice Address of the authorized cross-chain token bridge (IERC7802 caller).
    address public tokenBridge;

    // =============================================================
    // Modifiers
    // =============================================================

    /**
    * @notice Restricts access to accounts with the admin role.
    * @dev Reverts with "Not allowed" if the caller is not an admin.
    */
    modifier onlyAdmin() {
        require(admin[_msgSender()] == true, "Not allowed");
        _;
    }

   /**
    * @notice Restricts access to admins or authority-role accounts.
    * @dev Authority accounts can freeze/unfreeze addresses. Admins always pass this check.
    */
    modifier onlyAuthority() {
        require(admin[_msgSender()] == true || authority[_msgSender()] == true, "Not allowed");
        _;
    }

    /**
    * @notice Restricts access to admins or custody-role accounts.
    * @dev Custody accounts can manage KYC status and buyback limits. Admins always pass this check.
    */
    modifier onlyCustody() {
        require(admin[_msgSender()] == true || custody[_msgSender()] == true, "Not allowed");
        _;
    }

    /**
    * @notice Restricts access to admins or minter-role accounts.
    * @dev Admins always pass this check.
    */
    modifier onlyMinter() {
        require(admin[_msgSender()] == true || minter[_msgSender()] == true, "Not allowed");
        _;
    }

    /**
    * @notice Requires the contract to not be paused.
    * @dev Reverts with "Contract is paused" when `pause` is true.
    */
    modifier notPaused() {
        require(pause == false, "Contract is paused");
        _;
    }

    /**
    * @notice Restricts access to the configured cross-chain token bridge.
    * @dev Reverts with "Only Token Bridge can call" if caller is not `tokenBridge`.
    */
    modifier onlyTokenBridge() {
    require(_msgSender() == tokenBridge, "Only Token Bridge can call");
    _;
  }

    // =============================================================
    // Events
    // =============================================================
    event freeze(address indexed addr, bool indexed status);
    event redeemEvent(address indexed addr, uint256 indexed amount, uint256 indexed opt);
    event onchainBuyBackEvent(address indexed to, uint256 goldprice, uint256 buybackprice, uint256 fees, uint256 goldamount, uint256 indexed tokenamount);
    event pauseContract(bool indexed status);
    event buyTokens(address indexed addr, uint256 indexed nooftokens, uint256 goldprice, uint256 goldpremiumprice, uint256 fees, uint256 indexed amount);
    event kycUpdate(address indexed addr, bool indexed status, uint256 indexed limit);
    event LogTokenBridge(address indexed tokenBridge);
    event Burn(address indexed from, uint256 amount);
    event Mint(address indexed _destination, uint256 _amount);

    // =============================================================
    // Constructor
    // =============================================================

    /**
     * @notice Constructor for StableGold
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _premintSupply Amount to mint to deployer at deployment
     * @param _initialMaxSupply Initial maximum supply cap
     * @param _priceFeed Address of Chainlink gold price feed
     * @param _dataFeedHeartbeat Maximum age of price data (in seconds)
     */
    constructor(string memory _name, string memory _symbol, uint256 _premintSupply, uint256 _initialMaxSupply, address _priceFeed, uint256 _dataFeedHeartbeat) ERC20(_name, _symbol) {
        premintSupply = _premintSupply; // pre-minted supply
        _mint(_msgSender(), premintSupply); // mints pre-minted supply if any
        admin[_msgSender()] = true; // makes msg.sender an admin
        maxSupply = _initialMaxSupply; // max initial supply that can be minted
        priceFeed = IDataFeed(_priceFeed); // contract address for gold prices
        dataFeedHeartbeat = _dataFeedHeartbeat; // time to check for new datafeed
        burnRedeem = true; // removes redeem tokens from total supply
        buyBackAddress = address(this); // buyback address for OTC buy backs is set to contract address
        pause = true; // contract is paused
        require(maxSupply >= premintSupply, "Max supply must exceed premint supply");
        require(dataFeedHeartbeat > 0, "Heartbeat must be > 0");
    }

    /**
    * @notice Grants or revokes admin role for an address.
    * @dev Only callable by the contract owner. Admins can manage minters, authorities, custody, and fees.
    * @param _address Account to update.
    * @param _status True to grant admin, false to revoke.
    */
    function addAdmin(address _address, bool _status) public onlyOwner {
        admin[_address] = _status;
    }

    /**
    * @notice Grants or revokes minter role for an address.
    * @dev Only callable by an admin.
    * @param _address Account to update.
    * @param _status True to grant minter, false to revoke.
    */
    function addMinter(address _address, bool _status) public onlyAdmin {
        minter[_address] = _status;
    }

    /**
    * @notice Grants or revokes authority role for an address.
    * @dev Authority accounts can freeze/unfreeze addresses. Only callable by an admin.
    * @param _address Account to update.
    * @param _status True to grant authority, false to revoke.
    */
    function addAuthority(address _address, bool _status) public onlyAdmin {
        authority[_address] = _status;
    }

    /**
    * @notice Grants or revokes custody role for an address.
    * @dev Custody accounts can manage KYC. Only callable by an admin.
    * @param _address Account to update.
    * @param _status True to grant custody, false to revoke.
    */
    function addCustody(address _address, bool _status) public onlyAdmin {
        custody[_address] = _status;
    }

    /**
    * @notice Sets the purchase premium applied on top of spot gold price.
    * @dev Only callable by an admin. Value is in basis points (100 = 1%).
    * @param _premium New premium in basis points.
    */
    function updatePremium(uint256 _premium) public onlyAdmin {
        premium = _premium;
    }

    /**
    * @notice Sets the fee deducted from spot price during on-chain buyback.
    * @dev Only callable by an admin. Value is in basis points (100 = 1%).
    * @param _onchainBuyBackFee New fee in basis points.
    */
    function updateOnChainBuyBackFee(uint256 _onchainBuyBackFee) public onlyAdmin {
        onchainBuyBackFee = _onchainBuyBackFee;
    }

    /**
    * @notice Freezes or unfreezes a single address.
    * @dev Frozen addresses cannot transfer, burn, or receive tokens. Emits {freeze}.
    * @param _address Account to update.
    * @param _status True to freeze, false to unfreeze.
    */
    function freezeAddress(address _address, bool _status) public onlyAuthority {
        freezeList[_address] = _status;
        emit freeze(_address, _status);
    }

    /**
    * @notice Freezes or unfreezes multiple addresses in one transaction.
    * @dev Arrays must be the same length. Emits {freeze} for each address.
    * @param _addresses Accounts to update.
    * @param _status Freeze status for each corresponding address.
    */
    function batchFreezeAddresses(address[] memory _addresses, bool[] memory _status) public onlyAuthority {
        require(_addresses.length == _status.length, "Check arrays size");
        for (uint256 i=0; i < _addresses.length; i++) {
            freezeList[_addresses[i]] = _status[i];
            emit freeze(_addresses[i], _status[i]);
        }
    }

    /**
    * @notice Pauses or unpauses the contract.
    * @dev Only callable by the owner. Emits {pauseContract}.
    * @param _status True to pause, false to unpause.
    */
    function pauseStatus(bool _status) public onlyOwner {
        pause = _status;
        emit pauseContract(_status);
    }

    /**
    * @notice Enables or disables public token sales via `buy`.
    * @dev When false, only KYC-approved custody accounts may call `buy`.
    * @param _status True to enable public sales, false to restrict.
    */
    function updateSaleStatus(bool _status) public onlyOwner {
        saleStatus = _status;
    }

    /**
    * @notice Sets the minimum and maximum amounts allowed per `redeem` call.
    * @dev Only callable by the owner. `_max` must be greater than `_min`.
    * @param _max Maximum redeem amount in token units.
    * @param _min Minimum redeem amount in token units.
    */
    function updateRedeemMaxMinAmount(uint256 _max, uint256 _min) public onlyOwner {
        require(_max > _min, "Max needs to be larger than min");
        maxAmountforRedeem = _max;
        minAmountforRedeem = _min;
    }

    /**
    * @notice Enables or disables cross-chain mint and burn via the token bridge.
    * @param _status True to enable, false to disable.
    */
    function updateCrossChainStatus(bool _status) public onlyOwner {
        crossChainStatus = _status;
    }

    /**
    * @notice Sets the destination address for OTC buyback redemptions.
    * @dev Used by `redeem` when `_opt = 2`.
    * @param _buyBackAddress New buyback recipient address.
    */
    function updateBuyBackAddress(address _buyBackAddress) public onlyOwner {
        buyBackAddress = _buyBackAddress;
    }

    /**
    * @notice Updates KYC status and on-chain buyback limit for an address.
    * @dev Only callable by custody or admin. Emits {kycUpdate}.
    * @param _address Account to update.
    * @param _status True if KYC approved, false otherwise.
    * @param _onChainBBLimit Maximum StableGold spendable via on-chain buyback.
    */
    function updateKYCStatus(address _address, bool _status, uint256 _onChainBBLimit) public onlyCustody {
        kycStatus[_address] = _status;
        onChainBBLimit[_address] = _onChainBBLimit;
        emit kycUpdate(_address, _status, _onChainBBLimit);
    }

    /**
    * @notice Batch-updates KYC status and buyback limits for multiple addresses.
    * @dev All arrays must be the same length. Emits {kycUpdate} per address.
    * @param _addresses Accounts to update.
    * @param _status KYC status for each address.
    * @param _onChainBBLimit Buyback limit for each address.
    */
    function updateKYCAddressBatch(address[] memory _addresses, bool[] memory _status, uint256[] memory _onChainBBLimit) public onlyCustody {
        require(_addresses.length == _status.length, "Check arrays size");
        for (uint256 i = 0; i < _addresses.length; i++) {
            kycStatus[_addresses[i]] = _status[i];
            onChainBBLimit[_addresses[i]] = _onChainBBLimit[i];
            emit kycUpdate(_addresses[i], _status[i], _onChainBBLimit[i]);
        }
    }

    /**
    * @notice Enables or disables physical gold redemption.
    * @dev Controls `redeem` when `_opt = 1`.
    * @param _redeemStatus True to enable, false to disable.
    */
    function updateRedeemStatus(bool _redeemStatus) public onlyOwner {
        redeemStatus = _redeemStatus;
    }

    /**
    * @notice Updates the gold price oracle and its staleness threshold.
    * @dev `_dataFeedHeartbeat` must be greater than zero.
    * @param _priceFeed Address of the new price feed contract.
    * @param _dataFeedHeartbeat Maximum age of price data in seconds.
    */
    function updatePriceFeed(address _priceFeed, uint256 _dataFeedHeartbeat) public onlyOwner {
        priceFeed = IDataFeed(_priceFeed);
        dataFeedHeartbeat = _dataFeedHeartbeat;
        require(dataFeedHeartbeat > 0, "Heartbeat must be > 0");
    }

    /**
    * @notice Sets whether redeemed tokens are burned or sent to the dead address.
    * @param _burnRedeem True to burn, false to transfer to 0x…dEaD.
    */
    function updateBurnRedeemStatus(bool _burnRedeem) public onlyOwner {
        burnRedeem = _burnRedeem;
    }

   /**
    * @notice Enables or disables OTC buyback via `redeem`.
    * @dev Controls `redeem` when `_opt = 2`.
    * @param _buyBackStatus True to enable, false to disable.
    */
    function updateBuyBackStatus(bool _buyBackStatus) public onlyOwner {
        buyBackStatus = _buyBackStatus;
    }

    /**
    * @notice Enables or disables on-chain buyback via `onchainBuyBack`.
    * @param _onchainbuyBackStatus True to enable, false to disable.
    */
    function updateOnChainBuyBackStatus(bool _onchainbuyBackStatus) public onlyOwner {
        onchainbuyBackStatus = _onchainbuyBackStatus;
    }

    /**
    * @notice Increases the maximum supply by adding the specified amount.
    * @param _newSupply The amount by which to increase `maxSupply`.
    */
    function increaseSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = maxSupply + _newSupply;
    }

    /**
    * @notice Decreases the maximum supply by the specified amount, ensuring it remains at or above the current total supply.
    * @param _decreaseSupply The amount by which to decrease `maxSupply`.
    */
    function decreaseSupply(uint256 _decreaseSupply) public onlyOwner {
        maxSupply = maxSupply - _decreaseSupply;
        require(maxSupply >= totalSupply(), "maxSupply can't be lower than Total Supply");
    }

    /**
    * @notice Mints tokens to a specified address (callable by minters when not paused).
    *         Enforces freeze-list checks and either maxSupply or proof-of-reserve limits.
    * @dev Only callable by an admin or minter while the contract is unpaused.
    *      Recipient must not be frozen. Supply is capped by `maxSupply` when
    *      proof-of-reserve is disabled, or by the reserve feed when
    *      `proofOfReserveEnabled` is true (feed data must be fresh within
    *      `chainReserveHeartbeat`).
    * @param _to The address that will receive the minted tokens.
    * @param amount The amount of tokens to mint.
    */
    function mint(address _to, uint256 amount) public onlyMinter notPaused {
        require(freezeList[_to] == false, "Not allowed");
        if (chainReserveFeed == address(0) || proofOfReserveEnabled == false) {
            require(totalSupply() + amount <= maxSupply, "Supply can't exceed maxSupply");
            _mint(_to, amount);
        } else {
            // Get latest proof-of-reserves from the feed
            (, int256 signedReserves, , uint256 updatedAt, ) = AggregatorV3Interface(chainReserveFeed).latestRoundData();
            require(signedReserves > 0, "Invalid answer from PoR feed");
            uint256 reserves = uint256(signedReserves);
            // Sanity check: is answer updatedAt in the past
            require(block.timestamp >= updatedAt, "Invalid PoR updatedAt");
            // Check the answer is fresh enough (i.e., within the specified heartbeat)
            require(block.timestamp - updatedAt <= chainReserveHeartbeat, "PoR answer too old");
            require(totalSupply() + amount <= reserves, "Supply can't exceed Reserves");
            _mint(_to, amount);
        }
    }

    /**
    * @notice Sets the chain reserve feed address, enables or disables proof-of-reserve, and updates the heartbeat.
    * @dev Only callable by the owner. When `_status` is true, `_newFeed` must not
    *      be the zero address. `_chainReserveHeartbeat` must be greater than zero.
    *      When enabled, minting in `mint` and `buy` is capped by reserve feed data
    *      instead of `maxSupply`.
    * @param _newFeed The address of the new chain reserve feed contract.
    * @param _status True to enable proof-of-reserve, false to disable.
    * @param _chainReserveHeartbeat The maximum age (in seconds) allowed for a valid PoR answer.
    */
    function setChainReserveFeed(address _newFeed, bool _status, uint256 _chainReserveHeartbeat) public onlyOwner {
        chainReserveFeed = _newFeed;
        proofOfReserveEnabled = _status;
        if (proofOfReserveEnabled == true) {
            require(chainReserveFeed != address(0), "Zero address Error");
        }
        chainReserveHeartbeat = _chainReserveHeartbeat;
        require(chainReserveHeartbeat > 0, "Heartbeat must be > 0");
    }

    /**
    * @notice Purchases StableGold by paying an accepted stablecoin.
    * @dev Requires contract to be unpaused. Recipient must not be frozen.
    *      When `saleStatus` is false, caller must be KYC-approved custody.
    *      Accepts stablecoins with 6 or 18 decimals only.
    * @param _to Recipient of minted StableGold.
    * @param _token Accepted stablecoin contract address.
    * @param amount Stablecoin amount in the token's native decimals.
    */
    function buy(address _to, address _token, uint256 amount) public notPaused {
        require(freezeList[_to] == false, "Not allowed");
        require(acceptedTokens[_token] == true && amount > 0, "Invalid token address / Invalid amount");
        if (saleStatus == false) {
            require((kycStatus[_msgSender()] == true && custody[_msgSender()] == true), "Buyer not authorised");
        }
        (, int256 goldPriceData, , uint256 updatedAt,) = priceFeed.latestRoundData();
        require(goldPriceData > 0, "Invalid answer from Datafeed");
        // Sanity check: is answer updatedAt in the past
        require(block.timestamp >= updatedAt, "Invalid Datafeed updatedAt");
        // Check the answer is fresh enough (i.e., within the specified heartbeat)
        require(block.timestamp - updatedAt <= dataFeedHeartbeat, "Datafeed answer too old");
         // Get token decimals (only allow 6 or 18 – most common cases)
        uint8 tokenDec = IERC20Metadata(_token).decimals();
        require(tokenDec == 6 || tokenDec == 18, "Only 6 or 18 decimal tokens accepted");
        // calculate gold price in grams and include premium
        uint256 goldPrice = uint256(goldPriceData) * 10000000 / 311034768; // 1 troy ounce = 31.1034768g
        uint256 goldPricePremium = goldPrice + (goldPrice * premium / 10000);
        // calculate number of tokens to mint
        uint256 noOfTokens;
        if (tokenDec == 18) {
            noOfTokens = amount * 100000000 / goldPricePremium; // x by 100000000 as datafeed has 8 decimals
            require(noOfTokens > 0,"Min amount required");
        } else if (tokenDec == 6) {
            noOfTokens = amount * 1e12 * 100000000 / goldPricePremium; // x by 100000000 as datafeed has 8 decimals
            require(noOfTokens > 0,"Min amount required");
        }
        // check reserves
        if (chainReserveFeed == address(0) || proofOfReserveEnabled == false) {
            require(totalSupply() + noOfTokens <= maxSupply, "Supply can't exceed maxSupply");
            _mint(_to, noOfTokens);
        } else {
            // Get latest proof-of-reserves from the feed
            (, int256 signedReserves, , uint256 updatedAtReserves, ) = AggregatorV3Interface(chainReserveFeed).latestRoundData();
            require(signedReserves > 0, "Invalid answer from PoR feed");
            uint256 reserves = uint256(signedReserves);
            // Sanity check: is answer updatedAt in the past
            require(block.timestamp >= updatedAtReserves, "Invalid PoR updatedAt");
            // Check the answer is fresh enough (i.e., within the specified heartbeat)
            require(block.timestamp - updatedAtReserves <= chainReserveHeartbeat, "PoR answer too old");
            require(totalSupply() + noOfTokens <= reserves, "Supply can't exceed Reserves");
            _mint(_to, noOfTokens);
        }
        // transfer tokens to contract address
        uint256 calcFees;
        if (tokenDec == 18) { // 18 decimals transfer
            // store fees on mapping
            calcFees = (noOfTokens * (goldPrice * premium / 10000) / 100000000);
            collectedPremiums[_token] =  collectedPremiums[_token] + calcFees;
            IERC20(_token).safeTransferFrom(_msgSender(), address(this), amount);
            emit buyTokens(_to, noOfTokens, goldPrice, goldPricePremium, calcFees, amount);
        } else if (tokenDec == 6) { // 6 decimal transfers
            // store fees on mapping
            calcFees = (noOfTokens * (goldPrice * premium / 10000) / 100000000 / 1e12);
            collectedPremiums[_token] =  collectedPremiums[_token] + calcFees;
            IERC20(_token).safeTransferFrom(_msgSender(), address(this), amount);
            emit buyTokens(_to, noOfTokens, goldPrice, goldPricePremium, calcFees, amount);
        }
    }

    /**
    * @notice Burns tokens from a frozen address (callable by owner only).
    * @param _address The frozen address from which tokens will be burned.
    * @param amount The amount of tokens to burn.
    */
    function burnFreezedAssets(address _address, uint256 amount) public onlyOwner {
        require(freezeList[_address] == true, "Address is not frozen");
        _burn(_address, amount);
    }

    /**
    * @notice Transfers (reclaims) tokens from a frozen address to a specified recipient (callable by owner only).
    * @param _address The frozen address from which tokens will be transferred.
    * @param _to The address that will receive the tokens.
    * @param amount The amount of tokens to transfer.
    */
    function reclaim(address _address, address _to, uint256 amount) public onlyOwner {
        require(freezeList[_address] == true, "Address is not frozen");
        _transfer(_address, _to, amount);
    }
  
    /**
    * @notice Withdraws any ERC20 tokens sent to this contract (callable by owner only).
    * @param _contractAddress The address of the ERC20 token contract to withdraw from.
    * @param _to The address that will receive the withdrawn tokens.
    * @param _amount The amount of tokens to withdraw.
    */
    function withdrawERC20(address _contractAddress, address _to, uint256 _amount) public onlyOwner {
        IERC20(_contractAddress).safeTransfer(_to, _amount);
    }

    /**
    * @notice Withdraws collected fees (either premiums from buys or on-chain buyback fees) to a specified address (callable by owner only).
    * @param _opt 1 to withdraw collected premiums, any other value to withdraw collected buyback fees.
    * @param _token The address of the ERC20 token whose collected fees will be withdrawn.
    * @param _to The address that will receive the withdrawn fees.
    */
    function withdrawCollectedFees(uint256 _opt, address _token, address _to) public onlyOwner {
        if (_opt == 1) {
            IERC20(_token).safeTransfer(_to, collectedPremiums[_token]);
            collectedPremiums[_token] = 0;
        } else {
            IERC20(_token).safeTransfer(_to, collectedBBFees[_token]);
            collectedBBFees[_token] = 0;
        }             
    }

   /**
    * @notice Transfers tokens from the caller to a recipient, with freeze-list and pause checks (overrides ERC20).
    * @param to The address that will receive the tokens.
    * @param amount The amount of tokens to transfer.
    * @return bool True if the transfer succeeds.
    */
    function transfer(address to, uint256 amount) public virtual override notPaused returns (bool) {
        address owner = _msgSender();
        require(freezeList[owner] == false && freezeList[to] == false, "Not allowed");
        _transfer(owner, to, amount);
        return true;
    }

    /**
    * @notice Transfers tokens from one address to another using allowance, with freeze-list and pause checks (overrides ERC20).
    * @param from The address from which tokens will be transferred.
    * @param to The address that will receive the tokens.
    * @param amount The amount of tokens to transfer.
    * @return bool True if the transfer succeeds.
    */
    function transferFrom(address from, address to, uint256 amount) public virtual override notPaused returns (bool) {
        address spender = _msgSender();
        require(freezeList[from] == false && freezeList[to] == false && freezeList[spender] == false, "Not allowed");
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
    * @notice Burns tokens from the caller's balance, with freeze-list and pause checks (overrides ERC20).
    * @param amount The amount of tokens to burn.
    */
    function burn(uint256 amount) public virtual override notPaused {
        address owner = _msgSender();
        require (freezeList[owner] == false, "Not allowed");
        _burn(owner, amount);
    }

    /**
    * @notice Burns tokens from a specified account using allowance, with freeze-list and pause checks (overrides ERC20).
    * @param account The address from which tokens will be burned.
    * @param amount The amount of tokens to burn.
    */
    function burnFrom(address account, uint256 amount) public virtual override notPaused {
        address spender = _msgSender();
        require(freezeList[account] == false && freezeList[spender] == false, "Not allowed");
        _spendAllowance(account, spender, amount);
        _burn(account, amount);
    }

    /**
    * @notice Performs multiple token transfers in a single transaction by iterating over recipient and amount arrays.
    * @param _addresses Array of recipient addresses.
    * @param _amounts Array of corresponding token amounts to transfer (must match length of `_addresses`).
    */
    function batchTransfers(address[] memory _addresses, uint256[] memory _amounts) public {
        require(_addresses.length == _amounts.length, "Check arrays size");
        for (uint256 i=0; i< _addresses.length; i++) {
            transfer(_addresses[i], _amounts[i]);
        }
    }

    /**
    * @notice Retrieves the latest spot gold price data (with freshness checks) and calculates the price per gram including premium.
    * @dev Reads from `priceFeed` and reverts if data is invalid or older than
    *      `dataFeedHeartbeat`. Converts oracle price from troy ounce to per gram.
    * @return goldPriceData Raw oracle price (8 decimals, per troy ounce).
    * @return goldPrice Spot gold price per gram (internal scaling).
    * @return goldPricePremium Gold price per gram including `premium` (basis points).
    */
    function retrieveGoldPrices() public view returns (int256, uint256, uint256) {
        (, int256 goldPriceData, , uint256 updatedAt,) = priceFeed.latestRoundData();
        require(goldPriceData > 0, "Invalid answer from Datafeed");
        // Sanity check: is answer updatedAt in the past
        require(block.timestamp >= updatedAt, "Invalid Datafeed updatedAt");
        // Check the answer is fresh enough (i.e., within the specified heartbeat)
        require(block.timestamp - updatedAt <= dataFeedHeartbeat, "Datafeed answer too old");
        uint256 goldPrice = uint256(goldPriceData) * 10000000 / 311034768;  // in grams
        uint256 goldPricePremium = goldPrice + (goldPrice * premium / 10000);
        return (goldPriceData, goldPrice, goldPricePremium);
    }

    /**
    * @notice Retrieves the latest spot gold price data (with freshness checks) and calculates the on-chain buyback price per gram after fee deduction.
    * @dev Reads from `priceFeed` and reverts if data is invalid or older than
    *      `dataFeedHeartbeat`. Converts oracle price from troy ounce to per gram.
    * @return goldPriceData Raw oracle price (8 decimals, per troy ounce).
    * @return goldPrice Spot gold price per gram (internal scaling).
    * @return buybackPrice Gold price per gram after deducting `onchainBuyBackFee` (basis points).
    */
    function retrieveOnChainGoldBBPrices() public view returns (int256, uint256, uint256) {
        (, int256 goldPriceData, , uint256 updatedAt,) = priceFeed.latestRoundData();
        require(goldPriceData > 0, "Invalid answer from Datafeed");
        // Sanity check: is answer updatedAt in the past
        require(block.timestamp >= updatedAt, "Invalid Datafeed updatedAt");
        // Check the answer is fresh enough (i.e., within the specified heartbeat)
        require(block.timestamp - updatedAt <= dataFeedHeartbeat, "Datafeed answer too old");
        uint256 goldPrice = uint256(goldPriceData) * 10000000 / 311034768; // in grams;
        uint256 buybackPrice = goldPrice - (goldPrice * onchainBuyBackFee / 10000);
        return (goldPriceData, goldPrice, buybackPrice);
    }

    /**
    * @notice Retrieves the latest signed reserves value from the chain reserve data feed.
    * @return signedReserves The signed reserves amount from the feed.
    */
    function retrieveReserves() public view returns (int256) {
        (, int256 signedReserves, , , ) = AggregatorV3Interface(chainReserveFeed).latestRoundData();
        return signedReserves;
    }

    /**
    * @notice Redeems StableGold for physical gold or OTC buyback.
    * @dev Caller must be KYC-approved, not frozen, and within min/max redeem bounds.
    * @param amount StableGold amount to redeem.
    * @param _opt Redemption type: 1 = physical redemption, 2 = OTC buyback.
    * @return success True if redemption succeeded.
    */
    function redeem(uint256 amount, uint256 _opt) public notPaused returns (bool) {
        address owner = _msgSender();
        require(freezeList[owner] == false, "Not allowed");
        require(kycStatus[owner] == true, "No KYC");
        require(amount >= minAmountforRedeem && amount <= maxAmountforRedeem, "Max-min amount out of range");
        if (_opt == 1) { // physical redemption
        require(redeemStatus == true, "Redeem not active");
            if (burnRedeem == false) { // transfer to dead address, non-mintable
                _transfer(owner, 0x000000000000000000000000000000000000dEaD, amount);
            } else { // burn tokens, removes from totalSupply
                burn(amount);
            }
        } else if (_opt == 2) { // buyback OTC
            require(buyBackStatus == true, "Buy Back not activated");
            _transfer(owner, buyBackAddress, amount);
        } else {
            revert("Redeem Error");
        }
        emit redeemEvent(owner, amount, _opt);
        return true;
    }

    /**
    * @notice Adds or removes a stablecoin from the list of accepted tokens (callable by owner only).
    * @param _token The address of the stablecoin token.
    * @param _status True to accept the token, false to remove it.
    */
    function addAcceptedStables(address _token, bool _status) public onlyOwner {
        acceptedTokens[_token] = _status;
    }

    /**
    * @notice Approves a stablecoin contract to spend tokens for on-chain buyback (callable by admin only).
    * @param _token The address of the accepted stablecoin token.
    * @param _amount The amount to approve for spending by this contract.
    */
    function approveTokenContract(address _token, uint256 _amount) public onlyAdmin {
        require(acceptedTokens[_token] == true, "Invalid token address");
        IERC20(_token).forceApprove(address(this), _amount);
    }

    /**
    * @notice Sells StableGold for an accepted stablecoin at the on-chain buyback price.
    * @dev Caller must be KYC-approved, not frozen, and within their on-chain buyback limit.
    *      Requires `onchainbuyBackStatus` to be enabled and the contract to be unpaused.
    *      Transfers `_amount` StableGold from the caller to this contract, then sends
    *      stablecoins to `_to` based on spot gold price minus `onchainBuyBackFee`.
    *      Accepts stablecoins with 6 or 18 decimals only. Buyback fees are accrued in
    *      `collectedBBFees`. Emits {onchainBuyBackEvent}.
    * @param _to Recipient of the stablecoin payout.
    * @param _token Accepted stablecoin contract address.
    * @param _amount StableGold amount to sell (in token units).
    */
    function onchainBuyBack(address _to, address _token, uint256 _amount) public notPaused {
        require(acceptedTokens[_token] == true, "Invalid token address");
        address owner = _msgSender();
        require(freezeList[owner] == false, "Not allowed");
        require(kycStatus[owner] == true, "No KYC");
        // enable onchain
        require(onchainbuyBackStatus == true, "Onchain Buy Back not activated");
        // check buyback limits
        onChainBBSpending[owner] = onChainBBSpending[owner] + _amount;
        require(onChainBBSpending[owner] <= onChainBBLimit[owner], "Spending limit reached");
        // transfer stablegold to contract
        transfer(address(this), _amount);
        (, int256 goldPriceData, , uint256 updatedAt,) = priceFeed.latestRoundData();
        require(goldPriceData > 0, "Invalid answer from Datafeed");
        // Sanity check: is answer updatedAt in the past
        require(block.timestamp >= updatedAt, "Invalid Datafeed updatedAt");
        // Check the answer is fresh enough (i.e., within the specified heartbeat)
        require(block.timestamp - updatedAt <= dataFeedHeartbeat, "Datafeed answer too old");
        uint256 goldPrice = uint256(goldPriceData) * 10000000 / 311034768; // in grams;
        uint256 buybackPrice = goldPrice - (goldPrice * onchainBuyBackFee / 10000);
        // Get token decimals (only allow 6 or 18 – most common cases)
        uint8 tokenDec = IERC20Metadata(_token).decimals();
        require(tokenDec == 6 || tokenDec == 18, "Only 6 or 18 decimal tokens accepted");
        // Send tokens based on token decimals
        uint256 noOfTokens;
        uint256 calcFees;
        if (tokenDec == 18) {
            calcFees = (_amount * (goldPrice * onchainBuyBackFee / 10000) / 100000000);
            noOfTokens = (_amount * buybackPrice / 100000000); //  divide by 100000000 as datafeed has 8 decimals
            collectedBBFees[_token] =  collectedBBFees[_token] + calcFees;
        } else if (tokenDec == 6) {
            calcFees = ((_amount * (goldPrice * onchainBuyBackFee / 10000) / 100000000) / 1e12);
            noOfTokens = ((_amount * buybackPrice / 100000000) / 1e12);
            collectedBBFees[_token] =  collectedBBFees[_token] + calcFees;
        }
        // transfer stablecoins to seller
        require(noOfTokens > 0, "Failed");
        IERC20(_token).safeTransferFrom(address(this), _to, noOfTokens);
        emit onchainBuyBackEvent(_to, goldPrice, buybackPrice, calcFees, _amount, noOfTokens);
    }

    // Transfers and Receive With Authorization

    /**
     * @dev Returns the domain separator for the current chain.
     */

    string private constant DOMAIN_NAME = "Stablegold";
    string private constant DOMAIN_VERSION = "1";

    function domainSeparator()
        internal
        view
        virtual
        override
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes(DOMAIN_VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    function domainSeparatorPublic()
        public
        view
        virtual
        returns (bytes32, uint256)
    {
        return (domainSeparator(), block.chainid);
    }

    /**
    * @notice Execute a transfer with a signed authorization
    * @param from          Payer's address (Authorizer)
    * @param to            Payee's address
    * @param value         Amount to be transferred
    * @param validAfter    The time after which this is valid (unix time)
    * @param validBefore   The time before which this is valid (unix time)
    * @param nonce         Unique nonce
    * @param v             v of the signature
    * @param r             r of the signature
    * @param s             s of the signature
    */

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public notPaused {
        require(enableSignedTxs == true, "Signed Txs not enabled");
        require(freezeList[from] == false && freezeList[to] == false, "Not allowed");
        _transferWithAuthorizationValidityCheck(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            abi.encodePacked(r, s, v)
        );
        _transfer(from, to, value);
    }

    function transferWithAuthorizationSign(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes memory signature
    ) public notPaused {
        require(enableSignedTxs == true, "Signed Txs not enabled");
        require(freezeList[from] == false && freezeList[to] == false, "Not allowed");
        _transferWithAuthorizationValidityCheck(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            signature
        );
        _transfer(from, to, value);
    }

    /**
     * @notice Receive a transfer with a signed authorization from the payer
     * @dev This has an additional check to ensure that the payee's address
     * matches the caller of this function to prevent front-running attacks.
     * @param from          Payer's address (Authorizer)
     * @param to            Payee's address
     * @param value         Amount to be transferred
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param nonce         Unique nonce
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public notPaused {
        require(enableSignedTxs == true, "Signed Txs not enabled");
        require(freezeList[from] == false && freezeList[to] == false, "Not allowed");
        _receiveWithAuthorizationValidityCheck(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            abi.encodePacked(r, s, v)
        );
        _transfer(from, to, value);
    }

    function receiveWithAuthorizationSig(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes memory signature
    ) public notPaused {
        require(enableSignedTxs == true, "Signed Txs not enabled");
        require(freezeList[from] == false && freezeList[to] == false, "Not allowed");
        _receiveWithAuthorizationValidityCheck(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            abi.encodePacked(signature)
        );
        _transfer(from, to, value);
    }

    /**
    * @notice Recovers the EOA signer address from a given digest and signature.
    * @param digest The message digest that was signed.
    * @param signature The signature to recover the signer from.
    * @return address The recovered signer address.
    */
    function recoverSignerEOA(bytes32 digest, bytes memory signature) public pure returns (address) {
        return ECRecover.recover(digest, signature);
    }

    /**
    * @notice Encodes and hashes authorization data based on the specified type (transfer, receive, or cancel).
    * @param typ The authorization type (1 = transfer, 2 = receive, other = cancel).
    * @param from The address initiating the authorization.
    * @param to The recipient address (used for transfer/receive types).
    * @param value The token amount (used for transfer/receive types).
    * @param validAfter The timestamp after which the authorization is valid.
    * @param validBefore The timestamp before which the authorization is valid.
    * @param nonce The unique nonce for the authorization.
    * @return hash The keccak256 hash of the encoded authorization data.
    */
    function encodeData(uint256 typ, address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce) public pure returns (bytes32) {
        bytes32 datatype;
        if (typ == 1 || typ == 2) {
            if (typ == 1) {
                datatype = TRANSFER_WITH_AUTHORIZATION_TYPEHASH;
            } else if (typ == 2) {
                datatype = RECEIVE_WITH_AUTHORIZATION_TYPEHASH;
            }
            bytes32 hash = keccak256( abi.encode( datatype, from, to, value, validAfter, validBefore, nonce ));
            return (hash);
        } else {
            datatype = CANCEL_AUTHORIZATION_TYPEHASH;
            bytes32 hash = keccak256( abi.encode( datatype, from, nonce ));
            return (hash);
        }
    }

    /**
    * @notice Computes the EIP-712 digest from a domain separator and struct hash.
    * @param domainsep The EIP-712 domain separator.
    * @param structHash The hash of the structured data.
    * @return digest The resulting EIP-712 digest.
    */
    function getDigest(bytes32 domainsep, bytes32 structHash)
        public
        pure
        returns (bytes32 digest)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainsep)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }

    /**
    * @notice Enables or disables signed transactions.
    * @param _status True to enable signed transactions, false to disable.
    */
    function updateSignedTxsStatus(bool _status) public onlyOwner() {
        enableSignedTxs = _status;
    }

    /**
    * @notice Mints tokens to a destination address via the token bridge (cross-chain), with freeze-list, pause, and supply/reserve checks.
    * @param _destination The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    */
    function crosschainMint(address _destination, uint256 _amount) public override onlyTokenBridge notPaused {
        require(crossChainStatus == true, "Cross Chain not enabled");
        require(freezeList[_destination] == false, "Not allowed");
        if (chainReserveFeed == address(0) || proofOfReserveEnabled == false) {
            require(totalSupply() + _amount <= maxSupply, "Supply can't exceed maxSupply");
            _mint(_destination, _amount);
        } else {
            // Get latest proof-of-reserves from the feed
            (, int256 signedReserves, , uint256 updatedAt, ) = AggregatorV3Interface(chainReserveFeed).latestRoundData();
            require(signedReserves > 0, "Invalid answer from PoR feed");
            uint256 reserves = uint256(signedReserves);
            // Sanity check: is answer updatedAt in the past
            require(block.timestamp >= updatedAt, "Invalid PoR updatedAt");
            // Check the answer is fresh enough (i.e., within the specified heartbeat)
            require(block.timestamp - updatedAt <= chainReserveHeartbeat, "PoR answer too old");
            require(totalSupply() + _amount <= reserves, "Supply can't exceed Reserves");
            _mint(_destination, _amount);
        }
        emit Mint(_destination, _amount);
        emit CrosschainMint(_destination, _amount, _msgSender());
    }

    /**
    * @notice Burns tokens from a specified address via the token bridge (cross-chain), with freeze-list and pause checks.
    * @param _from The address from which tokens will be burned.
    * @param _amount The amount of tokens to burn.
    */
    function crosschainBurn(address _from, uint256 _amount) public override onlyTokenBridge notPaused {
        require(crossChainStatus == true, "Cross Chain not enabled");
        require(freezeList[_from] == false, "Not allowed");
        _burn(_from, _amount);
        emit Burn(_from, _amount);
        emit CrosschainBurn(_from, _amount, _msgSender());
    }

    /**
    * @notice Sets the token bridge address (callable by owner only).
    * @param _tokenBridge The address of the new token bridge contract.
    */
    function setTokenBridge(address _tokenBridge) external onlyOwner {
        tokenBridge = _tokenBridge;
        emit LogTokenBridge(_tokenBridge);
    }

    /**
    * @notice Checks whether the contract supports a given interface (IERC7802 or IERC165).
    * @param interfaceId The interface identifier to check.
    * @return bool True if the interface is supported, false otherwise.
    */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC7802).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

}