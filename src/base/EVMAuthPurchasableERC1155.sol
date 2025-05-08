// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EVMAuthBaseERC1155.sol";

/**
 * @title EVMAuthPurchasableERC1155
 * @dev Extension of the EVMAuthBaseERC1155 contract that enables the direct purchase and price management of tokens
 */
abstract contract EVMAuthPurchasableERC1155 is EVMAuthBaseERC1155 {
    // Wallet address for receiving payments
    address public wallet;

    // Roles
    bytes32 public constant FINANCE_MANAGER_ROLE = keccak256("FINANCE_MANAGER_ROLE");

    // Mapping from token ID to price
    mapping(uint256 => uint256) private _prices;

    // Events
    event FundsWithdrawn(address indexed wallet, uint256 amount);
    event TokenPurchased(address indexed account, uint256 indexed id, uint256 amount);
    event WalletChanged(address indexed oldWallet, address indexed newWallet);

    // Modifiers
    modifier requireForSale(uint256 id) {
        require(forSale(id), "Token is not for sale");
        _;
    }

    modifier requirePrice(uint256 id) {
        require(priceOf(id) > 0, "Token is priceless");
        _;
    }

    modifier requireValidWallet(address account) {
        // Check that the wallet address is not the zero address or this contract address
        require(account != address(0), "Invalid wallet address");
        require(account != address(this), "Invalid wallet address");
        _;
    }

    /**
     * @dev Constructor
     * @param _name Name of the EIP-712 signing domain
     * @param _version Current major version of the EIP-712 signing domain
     * @param _uri URI for ERC-1155 token metadata
     * @param _delay Delay (in seconds) for transfer of contract ownership
     * @param _owner Address of the contract owner
     */
    constructor(string memory _name, string memory _version, string memory _uri, uint48 _delay, address _owner)
        EVMAuthBaseERC1155(_name, _version, _uri, _delay, _owner)
    {
        // Grant all roles to the contract owner
        _grantRole(FINANCE_MANAGER_ROLE, _owner);

        // Set the initial wallet address to this contract address
        wallet = _owner;
    }

    /**
     * @dev Check if a token is active and has a price greater than 0
     * @param id The ID of the token to check
     * @return True if the token is purchasable, false otherwise
     */
    function forSale(uint256 id) public view returns (bool) {
        return active(id) && _prices[id] > 0;
    }

    /**
     * @dev Get the price of a token
     * @param id The ID of the token to check
     * @return The price of the token
     */
    function priceOf(uint256 id) public view returns (uint256) {
        return _prices[id];
    }

    /**
     * @dev Get the price of all tokens
     * @return result The prices of all tokens
     */
    function priceOfAll() public view returns (uint256[] memory result) {
        result = new uint256[](nextTokenId);
        for (uint256 i = 0; i < nextTokenId; i++) {
            result[i] = _prices[i];
        }
        return result;
    }

    /**
     * @dev Get the purchasing metadata for a batch of tokens
     * @param ids The IDs of the tokens to check
     * @return result The purchasing metadata for the tokens
     */
    function priceOfBatch(uint256[] memory ids) public view returns (uint256[] memory result) {
        result = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = _prices[ids[i]];
        }
        return result;
    }

    /**
     * @dev Purchase a token for a specific account
     * @param id The ID of the token to purchase
     * @param amount The amount of tokens to purchase
     */
    function purchase(address account, uint256 id, uint256 amount)
        external
        payable
        nonReentrant
        denyBlacklisted(account)
        denyBlacklistedSender
        requireForSale(id)
        requireValidWallet(wallet)
    {
        // If account is zero, use the sender's address
        if (account == address(0)) {
            account = _msgSender();
        }

        // Calculate the total price
        uint256 totalPrice = priceOf(id) * amount;
        require(msg.value >= totalPrice, "Insufficient payment");

        // Refund any excess payment
        uint256 refund = msg.value - totalPrice;
        if (refund > 0) {
            payable(_msgSender()).transfer(refund);
        }

        // Transfer the payment to the wallet
        payable(wallet).transfer(totalPrice);

        // Mint the purchased tokens to the buyer
        _mint(account, id, amount, "");

        emit TokenPurchased(account, id, amount);
    }

    /**
     * @dev Set the price for a token
     * @param id The ID of the token to set the price for
     * @param price The price of the token
     */
    function setPriceOf(uint256 id, uint256 price) public denyBlacklistedSender {
        require(hasRole(FINANCE_MANAGER_ROLE, _msgSender()), "Unauthorized finance manager");
        _prices[id] = price;
    }

    /**
     * @dev Set the price for a batch of tokens
     * @param ids The IDs of the tokens to set the price for
     * @param prices The prices of the tokens
     */
    function setPriceOfBatch(uint256[] memory ids, uint256[] memory prices) external denyBlacklistedSender {
        require(hasRole(FINANCE_MANAGER_ROLE, _msgSender()), "Unauthorized finance manager");
        require(ids.length == prices.length, "Array lengths do not match");
        for (uint256 i = 0; i < ids.length; i++) {
            _prices[ids[i]] = prices[i];
        }
    }

    /**
     * @dev Set the wallet address for receiving payments
     * @param value The new wallet address
     */
    function setWallet(address value) external requireValidWallet(value) {
        require(hasRole(FINANCE_MANAGER_ROLE, _msgSender()), "Unauthorized finance manager");
        address oldWallet = wallet;
        wallet = value;
        emit WalletChanged(oldWallet, value);
    }

    /**
     * @dev Move balance from this contract to wallet address
     */
    function withdraw() external payable nonReentrant requireValidWallet(wallet) {
        require(hasRole(FINANCE_MANAGER_ROLE, _msgSender()), "Unauthorized finance manager");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(wallet).transfer(balance);

        emit FundsWithdrawn(wallet, balance);
    }
}
