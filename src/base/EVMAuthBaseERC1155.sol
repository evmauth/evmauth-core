// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./EVMAuthAccessControl.sol";

/**
 * @title EVMAuthBaseERC1155
 * @dev Extension of OpenZeppelin's ERC-1155 contract that adds support for blacklisting, fund withdrawal,
 *      and token management functionality.
 */
abstract contract EVMAuthBaseERC1155 is ERC1155, EVMAuthAccessControl, ReentrancyGuard {
    // Unique project identifier, for cross-chain consistency
    bytes32 public immutable PROJECT_ID;

    // Roles
    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");
    bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");
    bytes32 public constant TOKEN_BURNER_ROLE = keccak256("TOKEN_BURNER_ROLE");

    // Data structure for token metadata
    struct BaseMetadata {
        uint256 id;
        bool active;
        bool burnable;
        bool transferable;
    }

    // Mapping from token ID to metadata
    mapping(uint256 => BaseMetadata) private _metadata;

    // Auto-incrementing token ID
    uint256 internal nextTokenId = 0;

    /**
     * @dev Constructor
     * @param _name Name identifier for the project
     * @param _version Version identifier for the project
     * @param _uri URI for ERC-1155 token metadata (e.g., "https://example.com/token/{id}.json")
     * @param _delay Delay (in seconds) for transfer of contract ownership
     * @param _owner Address of the contract owner
     */
    constructor(string memory _name, string memory _version, string memory _uri, uint48 _delay, address _owner)
        ERC1155(_uri)
        EVMAuthAccessControl(_delay, _owner)
    {
        // Generate a unique project identifier using the keccak256 hash of the name
        PROJECT_ID = keccak256(abi.encodePacked(_name, _version));

        // Grant all roles to the contract owner
        _grantRole(TOKEN_MANAGER_ROLE, _owner);
        _grantRole(TOKEN_MINTER_ROLE, _owner);
        _grantRole(TOKEN_BURNER_ROLE, _owner);
    }

    /**
     * @dev Check if a token is active
     * @param id The ID of the token to check
     * @return True if the token is active, false otherwise
     */
    function active(uint256 id) public view returns (bool) {
        return _metadata[id].active;
    }

    /**
     * @dev Get the metadata of a token
     * @param id The ID of the token to check
     * @return The metadata of the token
     */
    function baseMetadataOf(uint256 id) public view returns (BaseMetadata memory) {
        return _metadata[id];
    }

    /**
     * @dev Get the metadata of all tokens
     * @return result The metadata of all tokens
     */
    function baseMetadataOfAll() public view returns (BaseMetadata[] memory) {
        BaseMetadata[] memory result = new BaseMetadata[](nextTokenId);
        for (uint256 i = 0; i < nextTokenId; i++) {
            result[i] = _metadata[i];
        }
        return result;
    }

    /**
     * @dev Get the metadata of a batch of tokens
     * @param ids The IDs of the tokens to check
     * @return result The metadata of the tokens
     */
    function baseMetadataOfBatch(uint256[] memory ids) public view returns (BaseMetadata[] memory) {
        BaseMetadata[] memory result = new BaseMetadata[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = _metadata[ids[i]];
        }
        return result;
    }

    /**
     * @dev Burn a token from an address; token must be burnable
     * @param from Address to burn tokens from
     * @param id Token ID to burn
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 id, uint256 amount) external {
        require(hasRole(TOKEN_BURNER_ROLE, _msgSender()), "Unauthorized burner");
        _burn(from, id, amount);
    }

    /**
     * @dev Check if a token is burnable
     * @param id The ID of the token to check
     * @return True if the token is burnable, false otherwise
     */
    function burnable(uint256 id) public view returns (bool) {
        return _metadata[id].burnable;
    }

    /**
     * @dev Burn a batch of tokens from an address; tokens must be burnable
     * @param from Address to burn tokens from
     * @param ids Array of token IDs to burn
     * @param amounts Array of amounts to burn
     */
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external {
        require(hasRole(TOKEN_BURNER_ROLE, _msgSender()), "Unauthorized burner");
        _burnBatch(from, ids, amounts);
    }

    /**
     * @dev Override to return false for blacklisted accounts
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if (isBlacklisted(account) || isBlacklisted(operator)) {
            return false;
        }
        return super.isApprovedForAll(account, operator);
    }

    /**
     * @dev Mint a new token and issue it to an address; token must be active
     * @param to Address to mint tokens to
     * @param id Token ID to mint
     * @param amount Amount of tokens to mint
     * @param data Additional data
     */
    function issue(address to, uint256 id, uint256 amount, bytes memory data) external {
        require(hasRole(TOKEN_MINTER_ROLE, _msgSender()), "Unauthorized minter");
        _mint(to, id, amount, data);
    }

    /**
     * @dev Mint a batch of tokens and issue them to an address; tokens must be active
     * @param to Address to mint tokens to
     * @param ids Array of token IDs to mint
     * @param amounts Array of amounts to mint
     * @param data Additional data
     */
    function issueBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external {
        require(hasRole(TOKEN_MINTER_ROLE, _msgSender()), "Unauthorized minter");
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Check if a token is transferable
     * @param id The ID of the token to check
     * @return True if the token is transferable, false otherwise
     */
    function transferable(uint256 id) public view returns (bool) {
        return _metadata[id].transferable;
    }

    /**
     * @dev Override to deny blacklisted accounts
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data)
        public
        virtual
        override
    {
        super.safeTransferFrom(from, to, id, value, data);
    }

    /**
     * @dev Override to deny blacklisted accounts
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        super.safeBatchTransferFrom(from, to, ids, values, data);
    }

    /**
     * @dev Override to deny blacklisted accounts
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        denyBlacklisted(operator)
        denyBlacklistedSender
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Set the base metadata for a token
     * @param id The ID of the token
     * @param _active Whether the token is active
     * @param _burnable Whether the token is burnable
     * @param _transferable Whether the token is transferable
     */
    function setBaseMetadata(uint256 id, bool _active, bool _burnable, bool _transferable) public {
        require(hasRole(TOKEN_MANAGER_ROLE, _msgSender()), "Unauthorized token manager");
        require(id <= nextTokenId, "Invalid token ID");

        _metadata[id] = BaseMetadata(id, _active, _burnable, _transferable);

        if (id == nextTokenId) {
            nextTokenId++;
        }
    }

    /**
     * @dev Override to declare support for interfaces
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControlDefaultAdminRules)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override to deny blacklisted accounts when minting, burning, or transferring tokens
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override
        denyBlacklisted(from)
        denyBlacklisted(to)
        denyBlacklistedSender
    {
        for (uint256 i = 0; i < ids.length; i++) {
            // Minting
            if (from == address(0)) {
                require(active(ids[i]), "Token is not active");
            }
            // Burning
            else if (to == address(0)) {
                require(burnable(ids[i]), "Token is not burnable");
            }
            // Transferring
            else {
                require(active(ids[i]), "Token is not active");
                require(transferable(ids[i]), "Token is not transferable");
            }
        }

        super._update(from, to, ids, values);
    }
}
