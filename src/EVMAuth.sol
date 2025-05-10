// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./base/EVMAuthExpiringERC1155.sol";

/**
 * @title EVMAuth
 * @dev Implementation of EVMAuthExpiringERC1155 that provides a unified method for metadata management
 */
contract EVMAuth is EVMAuthExpiringERC1155 {
    // Data structure for token metadata, including price and TTL
    struct TokenMetadata {
        uint256 id;
        bool active;
        bool burnable;
        bool transferable;
        uint256 price;
        uint256 ttl;
    }

    // Events
    event TokenMetadataCreated(uint256 indexed id, TokenMetadata metadata);
    event TokenMetadataUpdated(uint256 indexed id, TokenMetadata oldMetadata, TokenMetadata newMetadata);

    /**
     * @dev Constructor
     * @param name Name of the EIP-712 signing domain
     * @param version Current major version of the EIP-712 signing domain
     * @param uri URI for ERC-1155 token metadata
     * @param delay Delay (in seconds) for transfer of contract ownership
     * @param owner Address of the contract owner
     */
    constructor(string memory name, string memory version, string memory uri, uint48 delay, address owner)
        EVMAuthExpiringERC1155(name, version, uri, delay, owner)
    {}

    /**
     * @dev Get the metadata of a token
     * @param id The ID of the token to check
     * @return The metadata of the token, including price and TTL
     */
    function metadataOf(uint256 id) public view returns (TokenMetadata memory) {
        // Retrieve the base token metadata
        BaseMetadata memory baseMetadata = baseMetadataOf(id);

        // Retrieve the price and TTL for the token
        uint256 price = priceOf(id);
        uint256 ttl = ttlOf(id);

        // Combine all metadata into a single structure
        TokenMetadata memory metadata = TokenMetadata({
            id: baseMetadata.id,
            active: baseMetadata.active,
            burnable: baseMetadata.burnable,
            transferable: baseMetadata.transferable,
            price: price,
            ttl: ttl
        });

        return metadata;
    }

    function metadataOfAll() public view returns (TokenMetadata[] memory) {
        TokenMetadata[] memory result = new TokenMetadata[](nextTokenId);

        // Use *OfAll methods to efficiently collect metadata
        BaseMetadata[] memory baseMetadataArray = baseMetadataOfAll();
        uint256[] memory priceArray = priceOfAll();
        uint256[] memory ttlArray = ttlOfAll();

        // Combine all metadata into a single structure
        for (uint256 i = 0; i < nextTokenId; i++) {
            result[i] = TokenMetadata({
                id: baseMetadataArray[i].id,
                active: baseMetadataArray[i].active,
                burnable: baseMetadataArray[i].burnable,
                transferable: baseMetadataArray[i].transferable,
                price: priceArray[i],
                ttl: ttlArray[i]
            });
        }

        return result;
    }

    /**
     * @dev Get the metadata of a batch of tokens
     * @param ids The IDs of the tokens to check
     * @return result The metadata of the tokens, including price and TTL
     */
    function metadataOfBatch(uint256[] memory ids) public view returns (TokenMetadata[] memory) {
        TokenMetadata[] memory result = new TokenMetadata[](ids.length);

        // Use *OfBatch methods to efficiently collect metadata
        BaseMetadata[] memory baseMetadataArray = baseMetadataOfBatch(ids);
        uint256[] memory priceArray = priceOfBatch(ids);
        uint256[] memory ttlArray = ttlOfBatch(ids);

        // Combine all metadata into a single structure
        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = TokenMetadata({
                id: baseMetadataArray[i].id,
                active: baseMetadataArray[i].active,
                burnable: baseMetadataArray[i].burnable,
                transferable: baseMetadataArray[i].transferable,
                price: priceArray[i],
                ttl: ttlArray[i]
            });
        }

        return result;
    }

    /**
     * @dev Set comprehensive metadata for a token
     * @param id The ID of the token
     * @param _active Whether the token is active
     * @param _burnable Whether the token is burnable
     * @param _transferable Whether the token is transferable
     * @param _price The price of the token (0 if not for sale)
     * @param _ttl The time-to-live in seconds (0 for non-expiring)
     */
    function setMetadata(uint256 id, bool _active, bool _burnable, bool _transferable, uint256 _price, uint256 _ttl)
        external
    {
        require(hasRole(TOKEN_MANAGER_ROLE, _msgSender()), "Unauthorized token manager");

        // If the token ID already exists, capture its current state
        bool isUpdate = id < nextTokenId;
        TokenMetadata memory oldMetadata;
        if (isUpdate) {
            oldMetadata = metadataOf(id);
        }

        // Set base token metadata
        setBaseMetadata(id, _active, _burnable, _transferable);

        // Set token price (requires FINANCE_MANAGER_ROLE)
        if (hasRole(FINANCE_MANAGER_ROLE, _msgSender())) {
            setPriceOf(id, _price);
        }

        // Set token TTL (only if token is burnable)
        if (_burnable) {
            setTTL(id, _ttl);
        }

        // Emit event for token metadata creation or update
        TokenMetadata memory newMetadata = metadataOf(id);
        if (isUpdate) {
            emit TokenMetadataUpdated(id, oldMetadata, newMetadata);
        } else {
            emit TokenMetadataCreated(id, newMetadata);
        }
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the ERC].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the URI or any of the values
     * in the JSON file at said URI will be replaced by clients with the token ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token ID 0x4cce0.
     * @param value The URI to set
     */
    function setURI(string memory value) external {
        require(hasRole(TOKEN_MANAGER_ROLE, _msgSender()), "Unauthorized token manager");
        _setURI(value);
    }
}
