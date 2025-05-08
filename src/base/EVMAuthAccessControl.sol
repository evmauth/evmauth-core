// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

/**
 * @title EVMAuthAccessControl
 * @dev Extension of OpenZeppelin's AccessControlDefaultAdminRules contract that adds blacklist functionality
 */
abstract contract EVMAuthAccessControl is AccessControlDefaultAdminRules {
    // Roles
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");

    // Mapping for account address -> blacklisted status
    mapping(address => bool) private _blacklisted;

    // Events
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    // Modifiers
    modifier denyBlacklisted(address account) {
        require(!isBlacklisted(account), "Account is blacklisted");
        _;
    }

    modifier denyBlacklistedSender() {
        require(!isBlacklisted(_msgSender()), "Sender is blacklisted");
        _;
    }

    /**
     * @dev Constructor
     * @param _delay Delay (in seconds) for transfer of contract ownership
     * @param _owner Address of the contract owner
     */
    constructor(uint48 _delay, address _owner) AccessControlDefaultAdminRules(_delay, _owner) {
        _grantRole(BLACKLIST_MANAGER_ROLE, _owner);
    }

    /**
     * @dev Add a account to the blacklist; cannot blacklist a blacklist manager or the zero address
     * @param account The address of the account to blacklist
     */
    function addToBlacklist(address account) external onlyRole(BLACKLIST_MANAGER_ROLE) {
        require(!hasRole(BLACKLIST_MANAGER_ROLE, account), "Account is a blacklist manager");
        require(account != address(0), "Account is the zero address");

        _blacklisted[account] = true;

        emit AddedToBlacklist(account);
    }

    /**
     * @dev Add a batch of accounts to the blacklist
     * @param accounts The addresses of the accounts to blacklist
     */
    function addBatchToBlacklist(address[] memory accounts) external onlyRole(BLACKLIST_MANAGER_ROLE) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _blacklisted[accounts[i]] = true;
        }
    }

    /**
     * @dev Grant multiple roles to an account
     * @param roles Array of role identifiers to grant
     * @param account The address to grant the roles to
     */
    function grantRoles(bytes32[] memory roles, address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        denyBlacklisted(account)
    {
        for (uint256 i = 0; i < roles.length; i++) {
            // Skip DEFAULT_ADMIN_ROLE as it's handled by AccessControlDefaultAdminRules
            if (roles[i] == DEFAULT_ADMIN_ROLE) continue;

            grantRole(roles[i], account);
        }
    }

    /**
     * @dev Check if a account is blacklisted; if no account is provided, check if the sender is blacklisted
     * @param account The address of the account to check
     * @return True if the account is blacklisted, false otherwise
     */
    function isBlacklisted(address account) public view returns (bool) {
        if (account == address(0)) {
            return _blacklisted[_msgSender()];
        }
        return _blacklisted[account];
    }

    /**
     * @dev Remove a account from the blacklist
     * @param account The address of the account to remove from the blacklist
     */
    function removeFromBlacklist(address account) external onlyRole(BLACKLIST_MANAGER_ROLE) {
        delete _blacklisted[account];

        emit RemovedFromBlacklist(account);
    }

    /**
     * @dev Remove a batch of accounts from the blacklist
     * @param accounts The addresses of the accounts to remove from the blacklist
     */
    function removeBatchFromBlacklist(address[] memory accounts) external onlyRole(BLACKLIST_MANAGER_ROLE) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _blacklisted[accounts[i]] = false;
        }
    }

    /**
     * @dev Revoke multiple roles from an account
     * @param roles Array of role identifiers to revoke
     * @param account The address to revoke the roles from
     */
    function revokeRoles(bytes32[] memory roles, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < roles.length; i++) {
            // Skip DEFAULT_ADMIN_ROLE as it's handled by AccessControlDefaultAdminRules
            if (roles[i] == DEFAULT_ADMIN_ROLE) continue;

            revokeRole(roles[i], account);
        }
    }
}
