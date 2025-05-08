// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EVMAuthPurchasableERC1155.sol";

/**
 * @title EVMAuthExpiringERC1155
 * @dev Extension of the EVMAuthPurchasableERC1155 contract that adds expiration logic and management to tokens
 */
abstract contract EVMAuthExpiringERC1155 is EVMAuthPurchasableERC1155 {
    // Batch of tokens that expire at the same time
    struct Group {
        uint256 balance;
        uint256 expiresAt;
    }

    // Mapping from account -> token ID -> Group[]
    mapping(address => mapping(uint256 => Group[])) private _group;

    // Mapping from token ID to token time-to-live (TTL) in seconds
    mapping(uint256 => uint256) private _ttls;

    // Events
    event ExpiredTokensBurned(address indexed account, uint256 indexed id, uint256 amount);

    /**
     * @dev Constructor
     * @param _name Name of the EIP-712 signing domain
     * @param _version Current major version of the EIP-712 signing domain
     * @param _uri URI for ERC-1155 token metadata
     * @param _delay Delay (in seconds) for transfer of contract ownership
     * @param _owner Address of the contract owner
     */
    constructor(string memory _name, string memory _version, string memory _uri, uint48 _delay, address _owner)
        EVMAuthPurchasableERC1155(_name, _version, _uri, _delay, _owner)
    {}

    /**
     * @dev Override to exclude expired tokens
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        Group[] storage groups = _group[account][id];
        uint256 netBalance = super.balanceOf(account, id);
        uint256 _now = block.timestamp;

        // Exclude expired token balances
        for (uint256 i = 0; i < groups.length; i++) {
            if (groups[i].expiresAt <= _now) {
                netBalance -= groups[i].balance;
            }
        }

        return netBalance;
    }

    /**
     * @dev Get the balance of all tokens for a given account
     * @param account The address to check
     * @return Array of balances for each token ID
     */
    function balanceOfAll(address account) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](nextTokenId);
        for (uint256 i = 0; i < nextTokenId; i++) {
            balances[i] = balanceOf(account, i);
        }
        return balances;
    }

    /**
     * @dev Override to exclude expired tokens
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "Length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Get expiration details of token holdings for an account
     * @param account The address to check
     * @param id The token ID to check
     * @return Array of Group structs, with amount and expiration of each batch
     */
    function balanceDetailsOf(address account, uint256 id) external view returns (Group[] memory) {
        return _validGroups(account, id);
    }

    /**
     * @dev Get expiration details of token holdings for all tokens of an account
     * @param account The address to check
     * @return Array of Group arrays, with amount and expiration of each batch for each token ID
     */
    function balanceDetailsOfAll(address account) external view returns (Group[][] memory) {
        Group[][] memory result = new Group[][](nextTokenId);
        for (uint256 i = 0; i < nextTokenId; i++) {
            result[i] = _validGroups(account, i);
        }
        return result;
    }

    /**
     * @dev Get expiration details of token holdings for multiple accounts
     * @param accounts Array of addresses to check
     * @param ids Array of token IDs to check
     * @return result Array of Group arrays, with amount and expiration of each batch for each account
     */
    function balanceDetailsOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (Group[][] memory result)
    {
        require(accounts.length == ids.length, "Length mismatch");
        result = new Group[][](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            result[i] = _validGroups(accounts[i], ids[i]);
        }

        return result;
    }

    /**
     * @dev Adjust the token group balances in first-in-first-out (FIFO) order (earliest expiration first)
     * @param account The address of the account
     * @param id The ID of the token
     * @param amount The amount of tokens to burn
     */
    function _burnGroupBalances(address account, uint256 id, uint256 amount) internal {
        Group[] storage groups = _group[account][id];
        uint256 _now = block.timestamp;
        uint256 debt = amount;

        uint256 i = 0;
        while (i < groups.length && debt > 0) {
            if (groups[i].expiresAt <= _now) {
                i++;
                continue;
            }

            if (groups[i].balance > debt) {
                // Burn partial token group
                groups[i].balance -= debt;
                debt = 0;
            } else {
                // Burn entire token group
                debt -= groups[i].balance;
                groups[i].balance = 0;
            }
            i++;
        }
    }

    /**
     * @dev Generate the expiration timestamp for a token ID
     * @param id The ID of the token
     * @return The expiration timestamp (in seconds) for the token
     */
    function expirationFor(uint256 id) public view returns (uint256) {
        return ttlOf(id) == 0 ? type(uint256).max : block.timestamp + ttlOf(id);
    }

    /**
     * @dev Delete token groups that are expired or have no balance
     * @param account The address whose token groups need pruning
     * @param id The ID of the token
     */
    function _pruneGroups(address account, uint256 id) internal {
        Group[] storage groups = _group[account][id];
        uint256 _now = block.timestamp;

        // Shift valid groups to the front of the array
        uint256 index = 0;
        uint256 expiredAmount = 0;
        for (uint256 i = 0; i < groups.length; i++) {
            bool isValid = groups[i].balance > 0 && groups[i].expiresAt > _now;
            if (isValid) {
                if (i != index) {
                    groups[index] = groups[i];
                }
                index++;
            } else {
                expiredAmount += groups[i].balance;
            }
        }

        // Remove invalid groups from the end of the array
        while (groups.length > index) {
            groups.pop();
        }

        // If any expired groups were removed, emit an event with the total amount of expired tokens
        if (expiredAmount > 0) {
            emit ExpiredTokensBurned(account, id, expiredAmount);
        }
    }

    /**
     * @dev Transfer token groups from one account to another
     * @param from The source address
     * @param to The destination address
     * @param id The ID of the token
     * @param amount The amount of tokens to transfer
     */
    function _transferGroups(address from, address to, uint256 id, uint256 amount) internal {
        // Exit early if the transfer is to the same account or if the amount is zero
        if (from == to || amount == 0) return;

        Group[] storage groups = _group[from][id];
        uint256 _now = block.timestamp;
        uint256 debt = amount;

        // First pass: Reduce balances from sender's groups (FIFO order)
        for (uint256 i = 0; i < groups.length && debt > 0; i++) {
            // Skip token groups that are expired or have no balance
            if (groups[i].expiresAt <= _now || groups[i].balance == 0) {
                continue;
            }

            if (groups[i].balance > debt) {
                // Transfer partial token group
                _upsertGroup(to, id, debt, groups[i].expiresAt);
                groups[i].balance -= debt;
                debt = 0;
            } else {
                // Transfer entire token group
                _upsertGroup(to, id, groups[i].balance, groups[i].expiresAt);
                debt -= groups[i].balance;
                groups[i].balance = 0;
            }
        }

        // Clean up from account token groups that are expired or have zero balance
        _pruneGroups(from, id);
    }

    /**
     * @dev Set the time-to-live (TTL) for a token
     * @param id The ID of the token
     * @param value The TTL (in seconds) for the token; set to 0 (default) for perpetual tokens
     */
    function setTTL(uint256 id, uint256 value) public {
        require(hasRole(TOKEN_MANAGER_ROLE, _msgSender()), "Unauthorized token manager");
        require(burnable(id), "Token is not burnable, so it cannot expire");
        _ttls[id] = value;
    }

    /**
     * @dev Get the time-to-live (TTL) for a token
     * @param id The ID of the token
     * @return The TTL (in seconds) for the token
     */
    function ttlOf(uint256 id) public view returns (uint256) {
        return _ttls[id];
    }

    /**
     * @dev Get the time-to-live (TTL) for all tokens
     * @return result The TTL (in seconds) for each token
     */
    function ttlOfAll() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](nextTokenId);
        for (uint256 i = 0; i < nextTokenId; i++) {
            result[i] = _ttls[i];
        }
        return result;
    }

    /**
     * @dev Get the time-to-live (TTL) for a batch of tokens
     * @param ids The IDs of the tokens
     * @return result The TTL (in seconds) for each token in the batch
     */
    function ttlOfBatch(uint256[] memory ids) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = _ttls[ids[i]];
        }
        return result;
    }

    /**
     * @dev Override to update token expiration data on mint, burn, and transfer
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override
    {
        super._update(from, to, ids, values);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 _id = ids[i];
            uint256 _amount = values[i];

            // Minting
            if (from == address(0)) {
                address _account = to;
                uint256 _expiresAt = expirationFor(_id);
                _upsertGroup(_account, _id, _amount, _expiresAt);
            }
            // Burning
            else if (to == address(0)) {
                address _account = to;
                _burnGroupBalances(_account, _id, _amount);
                _pruneGroups(_account, _id);
            }
            // Transferring
            else {
                _transferGroups(from, to, _id, _amount);
            }
        }
    }

    /**
     * @dev Insert (or update) a token group for a given account and token ID
     * @param account The address of the account
     * @param id The ID of the token
     * @param amount The amount of tokens in the batch
     * @param expiresAt The expiration timestamp of the batch
     */
    function _upsertGroup(address account, uint256 id, uint256 amount, uint256 expiresAt) internal {
        Group[] storage groups = _group[account][id];

        // Find the correct position to insert the group (ordered by expiration, oldest to newest)
        uint256 insertIndex = groups.length;
        for (uint256 i = 0; i < groups.length; i++) {
            // Check if this is an insert or an update
            if (groups[i].expiresAt > expiresAt) {
                // Insert the new token group at this position
                insertIndex = i;
                break;
            } else if (groups[i].expiresAt == expiresAt) {
                // If a token group with same expiration exists, combine the balances and return
                groups[i].balance += amount;
                return;
            }
        }

        // If the new token group expires later than all the others, add it to the end of the array and return
        if (insertIndex == groups.length) {
            groups.push(Group({balance: amount, expiresAt: expiresAt}));
            return;
        }

        // Shift array elements to make room for the new token group
        groups.push(Group({balance: 0, expiresAt: 0})); // Add space at the end
        for (uint256 i = groups.length - 1; i > insertIndex; i--) {
            groups[i] = groups[i - 1];
        }

        // Insert the new Group at the correct position
        groups[insertIndex] = Group({balance: amount, expiresAt: expiresAt});
    }

    /**
     * @dev Get a filtered array of token groups for a given account and token ID, without expired or empty groups
     * @param account The address to check
     * @param id The token ID to check
     * @return Array of Group structs, with amount and expiration of each batch
     */
    function _validGroups(address account, uint256 id) internal view returns (Group[] memory) {
        // First, check if the account has any tokens
        uint256 balance = super.balanceOf(account, id);
        if (balance == 0) {
            // Return an empty array
            return new Group[](0);
        }

        Group[] storage groups = _group[account][id];
        uint256 _now = block.timestamp;

        // Count the groups that are not expired and have a balance
        uint256 validBatchCount = 0;
        for (uint256 i = 0; i < groups.length; i++) {
            if (groups[i].expiresAt > _now && groups[i].balance > 0) {
                validBatchCount++;
            }
        }

        // Create a new array of the correct size for valid groups
        Group[] memory details = new Group[](validBatchCount);
        uint256 index = 0;

        // Fill the array with valid groups, in the correct order (earliest expiration first)
        for (uint256 i = 0; i < groups.length; i++) {
            if (groups[i].expiresAt > _now && groups[i].balance > 0) {
                details[index] = groups[i];
                index++;
            }
        }

        return details;
    }
}
