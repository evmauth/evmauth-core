# EVMAuth Core

![Dynamic TOML Badge](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fgithub.com%2Fevmauth%2Fevmauth-core%2Fblob%2Fmain%2Ffoundry.toml&query=%24.solc&prefix=v&label=Solidity)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/evmauth/evmauth-core/test.yml?label=Tests)

**EVMAuth** is an advanced implementation of the [ERC-1155] token standard that enables robust EVM-based authorization for Web3 applications.

- **Drastically Reduced Infrastructure:** Eliminate the need for complex auth systems, user databases, and billing infrastructure, removing entire categories of technical debt from your codebase
- **AI-Ready Architecture:** Make your API instantly accessible to AI agents that cannot navigate traditional registration flows, opening your service to the next wave of digital economy growth
- **Built-In Security:** Replace permanent API keys with time-limited access tokens that naturally expire, dramatically reducing your attack surface without complex key rotation policies
- **Seamless Monetization:** For paid APIs, access purchases happen directly through the smart contract with instant settlement—no payment processors, invoicing, or collection issues
- **Flexible Access Control:** Offer different permission levels, durations, and price points with a tiered access control system that gives you precise control over API consumption

## Quick Start

### Setup

1. Install [Foundry](https://book.getfoundry.sh/):
   ```sh
   curl -L https://foundry.paradigm.xyz | bash
   ```

2. Copy `.env.example` to `.env` and set environment variables:
   ```sh
   cp .env.example .env
   ```

### Deploy Contract

1. Load environment variables:
    ```sh
    source .env
    ```

2. Predict contract address and project ID:
    ```sh
    forge script script/DeployEVMAuth.s.sol:DeployEVMAuth --sig "predictAddress()" --rpc-url "$RPC_URL"
    ```

3. Deploy EVMAuth contract:
    ```sh
    forge script script/DeployEVMAuth.s.sol:DeployEVMAuth --rpc-url "$RPC_URL" --broadcast
    ```

### Generate ABI & Bytecode

1. Generate EVMAuth contract ABI:
   ```sh
   forge inspect src/EVMAuth.sol:EVMAuth abi > src/EVMAuth.abi
   ```

2. Generate EVMAuth contract bytecode:
   ```sh
   forge inspect src/EVMAuth.sol:EVMAuth bytecode > src/EVMAuth.bin
   ```

### Run Tests

1. Run EVMAuthTest contract:
   ```sh
   forge test --match-contract EVMAuthTest
   ```

2. (Optional) Run test with traces and gas usage:
   ```sh
   forge test --match-contract EVMAuthTest -vvv
   ```

## Core Architecture

The **EVMAuth** contract is built with a modular architecture, extending several specialized contracts to provide a comprehensive feature set. The contract follows a hierarchical inheritance pattern:

```
EVMAuthAccessControl.sol
       ↑
EVMAuthBaseERC1155.sol
       ↑
EVMAuthPurchasableERC1155.sol
       ↑
EVMAuthExpiringERC1155.sol
       ↑
EVMAuth.sol
```

### EVMAuthAccessControl

This base layer extends OpenZeppelin's `AccessControlDefaultAdminRules` to add:

- Role-based access control
- Account blacklisting functionality
- Methods to grant and revoke multiple roles

### EVMAuthBaseERC1155

Building on the base access control, this layer adds:

- [ERC-1155] multi-token standard compliance
- Token metadata management (active/inactive, burnable, transferable)
- Incremental token ID generation
- Separate roles for token management, minting, and burning

### EVMAuthPurchasableERC1155

This extension adds financial functionality:

- Direct token purchases via EVM-compatible wallets
- Wallet and fund management capabilities
- Role for finance management
- Price configuration for different token types
- Sales monitoring via `TokenPurchased` events

### EVMAuthExpiringERC1155

This extension adds automatic token expiration functionality:

- Time-to-live (TTL) settings for tokens
- Automated token expiration and burning
- Grouping of tokens by expiration timestamp
- First-in-first-out (FIFO) burning and transferal of expiring tokens

### EVMAuth

The final implementation brings everything together with:

- Unified methods for setting and getting token metadata
- Events for tracking token metadata creation and changes

## Key Features

1. **EVM-Based Access Control**: Grant and revoke permissions using ownership of specific tokens

2. **Expiration Mechanics**: Tokens can have fixed durations, enabling subscription-like models

3. **Direct Purchase**: Users can buy access tokens directly from the contract if they have a price

4. **Cross-Chain Consistency**: Uses [ERC-2470] Singleton Factory for predictable addresses across EVMs

5. **Blacklisting**: Ability to block malicious accounts from interacting with the system

6. **Role Management**: Pre-defined roles for blacklisting, finance, token management, minting, and burning

## Practical Applications

This contract suite enables:

- **API Access Management**: Create and sell API access tokens without having to store them in a database

- **Subscription Services**: Implement renewable access with automatic and precise expiration

- **Metered Resource Access**: Sell tokens that can be redeemed for storage, network, or compute resources

- **Cross-Chain Identity**: Maintain consistent authentication and authorization across multiple EVMs

- **Token Gating**: Control access to digital or physical resources based on token ownership

## Deployment & Operation

The contract includes a deployment script using the [ERC-2470] Singleton Factory for cross-chain consistency. This
ensures the contract deploys to the same address across different EVMs when using the same parameters.

Key operational functions include:

- Setting token metadata (active/inactive, burnable, transferable, price, TTL)
- Monitoring token sales
- Verifying token ownership
- Handling token expiration

## Security Considerations

The contract implements several security measures:

- Non-reentrancy guards for financial functions
- Comprehensive role-based access controls
- Blacklisting capabilities for compromised accounts
- Delayed contract ownership transfer mechanism

## Contributing

To contribute to this open source project, please follow the guidelines in the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## License

The **EVMAuth** smart contract is released under the MIT License. See the [LICENSE](LICENSE) file for details.

[ERC-1155]: https://eips.ethereum.org/EIPS/eip-1155
[ERC-2470]: https://eips.ethereum.org/EIPS/eip-2470
