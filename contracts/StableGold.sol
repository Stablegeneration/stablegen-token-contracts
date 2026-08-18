// SPDX-License-Identifier: MIT

//  ███████╗████████╗ █████╗ ██████╗ ██╗     ███████╗ ██████╗ ███████╗███╗   ██╗
//  ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝ ██╔════╝████╗  ██║
//  ███████╗   ██║   ███████║██████╔╝██║     █████╗  ██║  ███╗█████╗  ██╔██╗ ██║
//  ╚════██║   ██║   ██╔══██║██╔══██╗██║     ██╔══╝  ██║   ██║██╔══╝  ██║╚██╗██║
//  ███████║   ██║   ██║  ██║██████╔╝███████╗███████╗╚██████╔╝███████╗██║ ╚████║
//  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝

/**
 * @title StableGen - StableGold
 * @notice Gold-backed ERC20 token with physical redemption, on-chain buyback, cross-chain support, and compliance features
 * @author StableGen Dev Team
 * @date 20-July-2026
 * @version 2.17.3
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
 * @title StableGold
 * @dev Main contract implementing a gold-backed stable token on Ethereum.
 * Combines ERC20 functionality with oracle pricing, role-based access control,
 * compliance features (KYC, freezing), and cross-chain capabilities.
 */

contract StableGold is ERC20, Ownable, ERC20Burnable, IERC7802, EIP3009 {

    // =============================================================
    // State Variables
    // =============================================================

    uint256 public maxSupply;
    uint256 public premium;
    uint256 public onchainBuyBackFee;
    uint256 public premintSupply;
    address public buyBackAddress;
    mapping (address => bool) public admin;
    mapping (address => bool) public authority;
    mapping (address => bool) public custody;
    mapping (address => bool) public freezeList;
    mapping (address => bool) public kycStatus;
    mapping (address => bool) public minter;
    mapping (address => uint256) public onChainBBLimit;
    mapping (address => uint256) public onChainBBSpending;
    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;
    bool public pause;
    bool public redeemStatus;
    IDataFeed public priceFeed;
    mapping (address => bool) public acceptedTokens;
    bool public burnRedeem;
    bool public saleStatus;
    bool public buyBackStatus;
    bool public onchainbuyBackStatus;
    bool public enableSignedTxs;
    bool public crossChainStatus;
    uint256 public dataFeedHeartbeat;
    uint256 public minAmountforRedeem;
    uint256 public maxAmountforRedeem;
    mapping (address => uint256) public collectedPremiums;
    mapping (address => uint256) public collectedBBFees;

    // Proof of Reserve feed related variables
    uint256 public chainReserveHeartbeat;
    address public chainReserveFeed;
    bool public proofOfReserveEnabled;

    // Cross chain
    address public tokenBridge;

    // =============================================================
    // Modifiers
    // =============================================================

    // admin role
    modifier onlyAdmin() {
        require(admin[_msgSender()] == true, "Not allowed");
        _;
    }

    // authority role
    modifier onlyAuthority() {
        require(admin[_msgSender()] == true || authority[_msgSender()] == true, "Not allowed");
        _;
    }

    // custody role
    modifier onlyCustody() {
        require(admin[_msgSender()] == true || custody[_msgSender()] == true, "Not allowed");
        _;
    }

    // minter role
    modifier onlyMinter() {
        require(admin[_msgSender()] == true || minter[_msgSender()] == true, "Not allowed");
        _;
    }

    // pause contract
    modifier notPaused() {
        require(pause == false, "Contract is paused");
        _;
    }

    // cross chain modifier
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
        require(maxSupply >= premintSupply, "Max supply must exceed premint supply"); // L-02
        require(dataFeedHeartbeat > 0, "Heartbeat must be > 0"); // L-07
    }

    // add admin
    function addAdmin(address _address, bool _status) public onlyOwner {
        admin[_address] = _status;
    }

    // add minter
    function addMinter(address _address, bool _status) public onlyAdmin {
        minter[_address] = _status;
    }

    // add authority
    function addAuthority(address _address, bool _status) public onlyAdmin {
        authority[_address] = _status;
    }

    // add custody
    function addCustody(address _address, bool _status) public onlyAdmin {
        custody[_address] = _status;
    }

    // update premium 1% = 100
    function updatePremium(uint256 _premium) public onlyAdmin {
        premium = _premium;
    }

    // update onchain buyback fee
    function updateOnChainBuyBackFee(uint256 _onchainBuyBackFee) public onlyAdmin {
        onchainBuyBackFee = _onchainBuyBackFee;
    }

    // freeze an address
    function freezeAddress(address _address, bool _status) public onlyAuthority {
        freezeList[_address] = _status;
        emit freeze(_address, _status);
    }

    // batch freeze
    function batchFreezeAddresses(address[] memory _addresses, bool[] memory _status) public onlyAuthority {
        require(_addresses.length == _status.length, "Check arrays size");
        for (uint256 i=0; i < _addresses.length; i++) {
            freezeList[_addresses[i]] = _status[i];
            emit freeze(_addresses[i], _status[i]);
        }
    }

    // pause contract
    function pauseStatus(bool _status) public onlyOwner {
        pause = _status;
        emit pauseContract(_status);
    }

    // update sale status
    function updateSaleStatus(bool _status) public onlyOwner {
        saleStatus = _status;
    }

    // update max and min amount for redeem
    function updateRedeemMaxMinAmount(uint256 _max, uint256 _min) public onlyOwner {
        require(_max > _min, "Max needs to be larger than min"); // L-01
        maxAmountforRedeem = _max;
        minAmountforRedeem = _min;
    }

    // update cross chain mint/burn status
    function updateCrossChainStatus(bool _status) public onlyOwner {
        crossChainStatus = _status;
    }

    // update buy back address
    function updateBuyBackAddress(address _buyBackAddress) public onlyOwner {
        buyBackAddress = _buyBackAddress;
    }

    // function to update address kyc status

    function updateKYCStatus(address _address, bool _status, uint256 _onChainBBLimit) public onlyCustody {
        kycStatus[_address] = _status;
        onChainBBLimit[_address] = _onChainBBLimit;
        emit kycUpdate(_address, _status, _onChainBBLimit);
    }

    // function to update kyc status for multiple addresses

    function updateKYCAddressBatch(address[] memory _addresses, bool[] memory _status, uint256[] memory _onChainBBLimit) public onlyCustody {
        require(_addresses.length == _status.length, "Check arrays size");
        for (uint256 i = 0; i < _addresses.length; i++) {
            kycStatus[_addresses[i]] = _status[i];
            onChainBBLimit[_addresses[i]] = _onChainBBLimit[i];
            emit kycUpdate(_addresses[i], _status[i], _onChainBBLimit[i]);
        }
    }

    // update the redeem status for physical redemption
    function updateRedeemStatus(bool _redeemStatus) public onlyOwner {
        redeemStatus = _redeemStatus;
    }

    // update the price feed contract
    function updatePriceFeed(address _priceFeed, uint256 _dataFeedHeartbeat) public onlyOwner {
        priceFeed = IDataFeed(_priceFeed);
        dataFeedHeartbeat = _dataFeedHeartbeat;
        require(dataFeedHeartbeat > 0, "Heartbeat must be > 0"); // L-07
    }

    // update the burn redeem status, if false -> dead address, if true -> burns the tokens
    function updateBurnRedeemStatus(bool _burnRedeem) public onlyOwner {
        burnRedeem = _burnRedeem;
    }

    // update the buyback redeem status, if true OTC buybacks are enabled
    function updateBuyBackStatus(bool _buyBackStatus) public onlyOwner {
        buyBackStatus = _buyBackStatus;
    }

    // update the onchain buyback status
    function updateOnChainBuyBackStatus(bool _onchainbuyBackStatus) public onlyOwner {
        onchainbuyBackStatus = _onchainbuyBackStatus;
    }

    // increase max supply value
    function increaseSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = maxSupply + _newSupply;
    }

    // decrease max supply value
    function decreaseSupply(uint256 _decreaseSupply) public onlyOwner {
        maxSupply = maxSupply - _decreaseSupply;
        require(maxSupply >= totalSupply(), "maxSupply can't be lower than Total Supply");
    }

    // mint as admin
    function mint(address _to, uint256 amount) public onlyMinter notPaused {
        require(freezeList[_to] == false, "Not allowed"); // H-01
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

    // set the chain reserves contract address
    function setChainReserveFeed(address _newFeed, bool _status, uint256 _chainReserveHeartbeat) public onlyOwner {
        chainReserveFeed = _newFeed;
        proofOfReserveEnabled = _status;
        if (proofOfReserveEnabled == true) {
            require(chainReserveFeed != address(0), "Zero address Error");
        }
        chainReserveHeartbeat = _chainReserveHeartbeat;
        require(chainReserveHeartbeat > 0, "Heartbeat must be > 0"); // L-07
    }

    // buy a token (amount based on token's decimals)
    function buy(address _to, address _token, uint256 amount) public notPaused {
        require(freezeList[_to] == false, "Not allowed"); // H-01
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
        if (tokenDec == 18) { // L-06
            noOfTokens = amount * 100000000 / goldPricePremium; // N-16 - x by 100000000 as datafeed has 8 decimals
            require(noOfTokens > 0,"Min amount required");
        } else if (tokenDec == 6) {
            noOfTokens = amount * 1e12 * 100000000 / goldPricePremium; // N-16 - x by 100000000 as datafeed has 8 decimals
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
            IERC20(_token).safeTransferFrom(_msgSender(), address(this), amount); // M-02
            emit buyTokens(_to, noOfTokens, goldPrice, goldPricePremium, calcFees, amount);
        } else if (tokenDec == 6) { // 6 decimal transfers
            // store fees on mapping
            calcFees = (noOfTokens * (goldPrice * premium / 10000) / 100000000 / 1e12);
            collectedPremiums[_token] =  collectedPremiums[_token] + calcFees;
            IERC20(_token).safeTransferFrom(_msgSender(), address(this), amount); // L-06
            emit buyTokens(_to, noOfTokens, goldPrice, goldPricePremium, calcFees, amount); // L-06
        }
    }

    // burn freezed tokens
    function burnFreezedAssets(address _address, uint256 amount) public onlyOwner {
        require(freezeList[_address] == true, "Address is not frozen");
        _burn(_address, amount);
    }

    // transfer freezed assets 
    function reclaim(address _address, address _to, uint256 amount) public onlyOwner {
        require(freezeList[_address] == true, "Address is not frozen");
        _transfer(_address, _to, amount);
    }
  
    // withdraw any ERC20 funds sent to the smart contract
    function withdrawERC20(address _contractAddress, address _to, uint256 _amount) public onlyOwner {
        IERC20(_contractAddress).safeTransfer(_to, _amount); // M-02
    }

    // withdraw fees collected froms buys or onchain buy backs
    function withdrawCollectedFees(uint256 _opt, address _token, address _to) public onlyOwner {
        if (_opt == 1) {
            IERC20(_token).safeTransfer(_to, collectedPremiums[_token]); // M-02
            collectedPremiums[_token] = 0;
        } else {
            IERC20(_token).safeTransfer(_to, collectedBBFees[_token]); // M-02
            collectedBBFees[_token] = 0;
        }             
    }

    // transfer override
    function transfer(address to, uint256 amount) public virtual override notPaused returns (bool) { // N-03
        address owner = _msgSender();
        require(freezeList[owner] == false && freezeList[to] == false, "Not allowed");
        _transfer(owner, to, amount);
        return true;
    }

    // transferFrom override
    function transferFrom(address from, address to, uint256 amount) public virtual override notPaused returns (bool) { // N-03
        address spender = _msgSender();
        require(freezeList[from] == false && freezeList[to] == false && freezeList[spender] == false, "Not allowed"); // H-01
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // burn override
    function burn(uint256 amount) public virtual override notPaused { // H-01 && L-05
        address owner = _msgSender();
        require (freezeList[owner] == false, "Not allowed");
        _burn(owner, amount);
    }

    // burnFrom override
    function burnFrom(address account, uint256 amount) public virtual override notPaused { // H-01 && L-05
        address spender = _msgSender();
        require(freezeList[account] == false && freezeList[spender] == false, "Not allowed");
        _spendAllowance(account, spender, amount);
        _burn(account, amount);
    }

    // batch transfers
    function batchTransfers(address[] memory _addresses, uint256[] memory _amounts) public {
        require(_addresses.length == _amounts.length, "Check arrays size");
        for (uint256 i=0; i< _addresses.length; i++) {
            transfer(_addresses[i], _amounts[i]);
        }
    }

    // retrieve spot gold prices in grams
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

    // retrieve onchain buyback prices in grams
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

    // retrieve reserves from datafeed
    function retrieveReserves() public view returns (int256) {
        (, int256 signedReserves, , , ) = AggregatorV3Interface(chainReserveFeed).latestRoundData();
        return signedReserves;
    }

    // redeem for physical redemption or OTC
    function redeem(uint256 amount, uint256 _opt) public notPaused returns (bool) {
        address owner = _msgSender();
        require(freezeList[owner] == false, "Not allowed");
        require(kycStatus[owner] == true, "No KYC");
        require(amount >= minAmountforRedeem && amount <= maxAmountforRedeem, "Max-min amount out of range"); // L-01 Restored the bound
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

    // function to add accepted stablecoins
    function addAcceptedStables(address _token, bool _status) public onlyOwner {
        acceptedTokens[_token] = _status;
    }

    // function to approve the stablecoin contracts to enable onchain buyback
    function approveTokenContract(address _token, uint256 _amount) public onlyAdmin {
        require(acceptedTokens[_token] == true, "Invalid token address");
        IERC20(_token).forceApprove(address(this), _amount); // M-02
    }

    // onchain buyback with fee
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
        require(noOfTokens > 0, "Failed"); // L-08
        IERC20(_token).safeTransferFrom(address(this), _to, noOfTokens); // M-02
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

    // check signer
    function recoverSignerEOA(bytes32 digest, bytes memory signature) public pure returns (address) { // L-09
        return ECRecover.recover(digest, signature);
    }

    // function to retrieve the data bytes and hash
    function encodeData(uint256 typ, address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce) public pure returns (bytes32) { // L-09
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

    // get digest
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

    // enable/disable signed txs
    function updateSignedTxsStatus(bool _status) public onlyOwner() {
        enableSignedTxs = _status;
    }

    // cross chain functions

    // allows the token bridge to mint tokens
    function crosschainMint(address _destination, uint256 _amount) public override onlyTokenBridge notPaused { // L-05
        require(crossChainStatus == true, "Cross Chain not enabled");
        require(freezeList[_destination] == false, "Not allowed"); // M-03
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

    // allows the token bridge to burn tokens
    function crosschainBurn(address _from, uint256 _amount) public override onlyTokenBridge notPaused { // L-05
        require(crossChainStatus == true, "Cross Chain not enabled");
        require(freezeList[_from] == false, "Not allowed"); // M-03
        _burn(_from, _amount);
        emit Burn(_from, _amount);
        emit CrosschainBurn(_from, _amount, _msgSender());
    }

    // set token bridge address
    function setTokenBridge(address _tokenBridge) external onlyOwner {
        tokenBridge = _tokenBridge;
        emit LogTokenBridge(_tokenBridge);
    }

    // supports interface function
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC7802).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

}