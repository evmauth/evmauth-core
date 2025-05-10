# EVMAuth Core

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/evmauth/evmauth-core/test.yml?label=Tests)
![GitHub Repo stars](https://img.shields.io/github/stars/evmauth/evmauth-core)

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

2. Verify [ERC-2470] Singleton Factory is deployed on the target network:
```sh
cast code 0xce0042B868300000d44A59004Da54A005ffdcf9f --rpc-url="$RPC_URL"
# 0x6080604052348015600f57600080fd5b506004361060285760003560e01c80634af63f0214602d575b600080fd5b60cf60048036036040811015604157600080fd5b810190602081018135640100000000811115605b57600080fd5b820183602082011115606c57600080fd5b80359060200191846001830284011164010000000083111715608d57600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929550509135925060eb915050565b604080516001600160a01b039092168252519081900360200190f35b6000818351602085016000f5939250505056fea26469706673582212206b44f8a82cb6b156bfcc3dc6aadd6df4eefd204bc928a4397fd15dacf6d5320564736f6c63430006020033
```

3. Predict contract address and project ID:
```sh
forge script script/DeployEVMAuth.s.sol:DeployEVMAuth --sig "predictAddress()" --rpc-url "$RPC_URL"
```

4. Deploy EVMAuth contract:
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

## Usage

### Set Token Metadata

1. Load environment variables:
```sh
source .env
```

2. Run this command:
```sh
cast send --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  "$CONTRACT_ADDRESS" \
  "setMetadata(uint256,bool,bool,bool,uint256,uint256)" \
  "$TOKEN_ID" \
  "$TOKEN_ACTIVE" \
  "$TOKEN_BURNABLE" \
  "$TOKEN_TRANSFERABLE" \
  "$TOKEN_PRICE" \
  "$TOKEN_TTL"
```

3. Check token metadata:
```sh
cast call --rpc-url "$RPC_URL" \
  "$CONTRACT_ADDRESS" \
  "metadataOf(uint256)(uint256,bool,bool,bool,uint256,uint256)" \
  "$TOKEN_ID"
```

### Purchase Token

1. Load environment variables:
```sh
source .env
```

2. Run this command:
```sh
cast send --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  "$CONTRACT_ADDRESS" \
  "purchase(address,uint256,uint256)" \
  "$ACCOUNT_ADDRESS" \
  "$TOKEN_ID" \
  "$TOKEN_AMOUNT" \
  --value "$PAYMENT_AMOUNT" \
  --gas-limit 150000
```

3. Check balance:
```sh
cast call --rpc-url "$RPC_URL" \
  "$CONTRACT_ADDRESS" \
  "balanceOf(address,uint256)(uint256)" \
  "$ACCOUNT_ADDRESS" \
  "$TOKEN_ID"
```

## Running Ethereum Locally

1. Start a local Ethereum node:
```sh
anvil --fork-url https://ethereum-sepolia-rpc.publicnode.com
```

2. Choose an account address and private key from the anvil output, which should look like this:
```sh


                             _   _
                            (_) | |
      __ _   _ __   __   __  _  | |
     / _` | | '_ \  \ \ / / | | | |
    | (_| | | | | |  \ V /  | | | |
     \__,_| |_| |_|   \_/   |_| |_|

    0.3.0 (5a8bd89 2024-12-20T08:45:53.195623000Z)
    https://github.com/foundry-rs/foundry


Available Accounts
==================

(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000.000000000000000000 ETH)
(1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000.000000000000000000 ETH)
(2) 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC (10000.000000000000000000 ETH)
(3) 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (10000.000000000000000000 ETH)
(4) 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (10000.000000000000000000 ETH)
(5) 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc (10000.000000000000000000 ETH)
(6) 0x976EA74026E726554dB657fA54763abd0C3a0aa9 (10000.000000000000000000 ETH)
(7) 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955 (10000.000000000000000000 ETH)
(8) 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f (10000.000000000000000000 ETH)
(9) 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 (10000.000000000000000000 ETH)

Private Keys
==================

(0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
(1) 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
(2) 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
(3) 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
(4) 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
(5) 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
(6) 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
(7) 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
(8) 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
(9) 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
```

3. Change these environment variables in your `.env` file, using the account address and private key from anvil:
```sh
RPC_URL=http://localhost:8545
ACCOUNT_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

4. Load environment variables:
```sh
source .env
```

5. Deploy, configure, and use the EVMAuth contract as described in the previous sections.
```sh
forge script script/DeployEVMAuth.s.sol:DeployEVMAuth --rpc-url "$RPC_URL" --broadcast
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
