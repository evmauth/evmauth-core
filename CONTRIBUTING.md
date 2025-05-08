# Contributing to EVMAuth

Thank you for your interest in contributing to EVMAuth! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Development Workflow](#development-workflow)
- [Commit Messages](#commit-messages)
- [Pull Requests](#pull-requests)
- [Questions?](#questions)
- [License](#license)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By
participating, you are expected to uphold this code. Please report unacceptable behavior to:
[opensource@radiustech.xyz](mailto:opensource@radiustech.xyz).

## Development Workflow

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/evmauth-core.git`
3. Create a new branch: `git checkout -b my-feature`
4. Make your changes
5. Run `forge fmt` and `forge test` to ensure code is formatted and tests pass
6. Push to your fork and submit a pull request

## Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation only
- `style:` Code style changes
- `refactor:` Non-bug-fixing code changes
- `test:` Test updates
- `chore:` Build process updates

## Pull Requests

1. Clear title following conventional commits
2. Detailed description of changes
3. Reference related issues
4. Update documentation
5. Add tests
6. Update CHANGELOG.md
7. Ensure CI checks pass

## Questions?

If you have questions:

1. Check existing issues
2. Create a new issue with `question` label
3. Ask in your PR if you're working on code

Thank you for your contributions!

[ERC-1155]: https://eips.ethereum.org/EIPS/eip-1155
[ERC-2470]: https://eips.ethereum.org/EIPS/eip-2470

## License

The **EVMAuth** smart contract is released under the MIT License. See the [LICENSE](LICENSE) file for details.
