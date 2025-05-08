# EVMAuth Core

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/evmauth/evmauth-core/test.yml?label=Tests)
![GitHub Org's stars](https://img.shields.io/github/stars/evmauth)

An advanced implementation of the [ERC-1155] token standard that enables robust EVM-based authorization.

[Learn more about EVMAuth](https://evmauth.github.io/)

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

## SDKs & Libraries

EVMAuth provides the following SDKs and libraries for easy integration with applications and frameworks:

- [TypeScript SDK](https://github.com/evmauth/evmauth-ts)

To request additional SDKs or libraries, create a new issue with the `question` label.

## Contributing

To contribute to this open source project, please follow the guidelines in the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## License

The **EVMAuth** contract is released under the MIT License. See the [LICENSE](LICENSE) file for details.

[ERC-1155]: https://eips.ethereum.org/EIPS/eip-1155
[ERC-2470]: https://eips.ethereum.org/EIPS/eip-2470
