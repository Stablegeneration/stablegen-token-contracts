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
 * @date 12-June-2026
 * @version 2.17.2
 */

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

pragma solidity ^0.8.25;

import "./IDataFeed.sol";
import "./AggregatorV3Interface.sol";
import "./IERC7802.sol";
import "./EIP3009.sol";
import "./SignatureChecker.sol";

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
        require(admin[msg.sender] == true, "Not allowed");
        _;
    }

    // authority role
    modifier onlyAuthority() {
        require(admin[msg.sender] == true || authority[msg.sender] == true, "Not allowed");
        _;
    }

    // custody role
    modifier onlyCustody() {
        require(admin[msg.sender] == true || custody[msg.sender] == true, "Not allowed");
        _;
    }

    // minter role
    modifier onlyMinter() {
        require(admin[msg.sender] == true || minter[msg.sender] == true, "Not allowed");
        _;
    }

    // pause contract
    modifier notPaused() {
        require(pause == false, "Contract is paused");
        _;
    }

    // cross chain modifier
    modifier onlyTokenBridge() {
    require(msg.sender == tokenBridge, "Only Token Bridge can call");
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
        _mint(msg.sender, premintSupply); // mints pre-minted supply if any
        admin[msg.sender] = true; // makes msg.sender an admin
        maxSupply = _initialMaxSupply; // max initial supply that can be minted
        priceFeed = IDataFeed(_priceFeed); // contract address for gold prices
        dataFeedHeartbeat = _dataFeedHeartbeat; // time to check for new datafeed
        burnRedeem = true; // removes redeem tokens from total supply
        buyBackAddress = address(this); // buyback address for OTC buy backs is set to contract address
        pause = true; // contract is paused
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
        chainReserveHeartbeat = _chainReserveHeartbeat;
    }

    // buy a token
    function buy(address _to, address _token, uint256 amount) public notPaused {
        require(acceptedTokens[_token] == true && amount > 0, "Invalid token address / Invalid amount");
        if (saleStatus == false) {
            require((kycStatus[msg.sender] == true && custody[msg.sender] == true), "Buyer not authorised");
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
        uint256 goldPrice = uint256(goldPriceData) * 10000000 / 311034768; // 1 troy ounce = 31.1034768g;
        uint256 goldPricePremium = goldPrice + (goldPrice * premium / 10000);
        // calculate number of tokens to mint
        uint256 noOfTokens = (amount / goldPricePremium) * 100000000; // x by 100000000 as datafeed has 8 decimals;
        require(noOfTokens > 0,"Min amount required"); // 0.0000000001 min token value allow to buy
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
            bool success = IERC20(_token).transferFrom(_msgSender(), address(this), amount);
            require(success, "Token transferFrom failed");
            emit buyTokens(_to, noOfTokens, goldPrice, goldPricePremium, calcFees, amount);
        } else if (tokenDec == 6) { // 6 decimal transfers
            // store fees on mapping
            calcFees = ((noOfTokens * (goldPrice * premium / 10000) / 100000000) / 1e12);
            collectedPremiums[_token] =  collectedPremiums[_token] + calcFees;
            bool success = IERC20(_token).transferFrom(_msgSender(), address(this), amount / 1e12);
            require(success, "Token transferFrom failed");
            emit buyTokens(_to, noOfTokens, goldPrice, goldPricePremium, calcFees, amount / 1e12);
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
        IERC20(_contractAddress).transfer(_to, _amount);             
    }

    // withdraw fees collected froms buys or onchain buy backs
    function withdrawCollectedFees(uint256 _opt, address _token, address _to) public onlyOwner {
        if (_opt == 1) {
            IERC20(_token).transfer(_to, collectedPremiums[_token]);
            collectedPremiums[_token] = 0;
        } else {
            IERC20(_token).transfer(_to, collectedBBFees[_token]);
            collectedBBFees[_token] = 0;
        }             
    }

    // transfer override
    function transfer(address to, uint256 amount) public notPaused virtual override returns (bool) {
        address owner = _msgSender();
        require(freezeList[owner] == false && freezeList[to] == false, "Not allowed");
        _transfer(owner, to, amount);
        return true;
    }

    // transferFrom override
    function transferFrom(address from, address to, uint256 amount) public notPaused virtual override returns (bool) {
        address spender = _msgSender();
        require(freezeList[from] == false && freezeList[to] == false, "Not allowed");
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
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
        (, int256 goldPriceData, , ,) = priceFeed.latestRoundData();
        uint256 goldPrice = uint256(goldPriceData) * 10000000 / 311034768;  // in grams
        uint256 goldPricePremium = goldPrice + (goldPrice * premium / 10000);
        return (goldPriceData, goldPrice, goldPricePremium);
    }

    // retrieve onchain buyback prices in grams
    function retrieveOnChainGoldBBPrices() public view returns (int256, uint256, uint256) {
        (, int256 goldPriceData, , ,) = priceFeed.latestRoundData();
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
            revert();
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
        IERC20(_token).approve(address(this), _amount);
    }

    // onchain buyback with fee
    function onchainBuyBack(address _to, address _token, uint256 _amount) public notPaused {
        require(acceptedTokens[_token] == true, "Invalid token address");
        address owner = _msgSender();
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
        bool success = IERC20(_token).transferFrom(address(this), _to, noOfTokens);
        require(success, "Token transferFrom failed");
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
    function recoverSigner(bytes32 digest, bytes memory signature) public pure returns (address) {
    return ECRecover.recover(digest, signature);
    }

    // function to retrieve the data bytes and hash
    function encodeData(uint256 typ, address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce) public pure returns (bytes memory, bytes32) {
        bytes32 datatype;
        if (typ == 1 || typ == 2) {
            if (typ == 1) {
                datatype = TRANSFER_WITH_AUTHORIZATION_TYPEHASH;
            } else if (typ == 2) {
                datatype = RECEIVE_WITH_AUTHORIZATION_TYPEHASH;
            }
            bytes memory data = abi.encodePacked(datatype,
                        from,
                        to,
                        value,
                        validAfter,
                        validBefore,
                        nonce);
            bytes32 hash = keccak256( abi.encode( datatype, from, to, value, validAfter, validBefore, nonce ));
            return (data, hash);
        } else {
            datatype = CANCEL_AUTHORIZATION_TYPEHASH;
            bytes memory data = abi.encodePacked(datatype,
                        from,
                        nonce);
            bytes32 hash = keccak256( abi.encode( datatype, from, nonce ));
            return (data, hash);
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
    function crosschainMint(address _destination, uint256 _amount) public override onlyTokenBridge notPaused {
        require(crossChainStatus == true, "Cross Chain not enabled");
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
        emit CrosschainMint(_destination, _amount, msg.sender);
    }

    // allows the token bridge to burn tokens
    function crosschainBurn(address _from, uint256 _amount) public override onlyTokenBridge {
        require(crossChainStatus == true, "Cross Chain not enabled");
        _burn(_from, _amount);
        emit Burn(_from, _amount);
        emit CrosschainBurn(_from, _amount, msg.sender);
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