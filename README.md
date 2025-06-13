# Malo-Labs

A Web3 decentralized application (dApp) built on Ethereum.

## Demo

DApp [Malo Labs](https://my-dapp-mauve.vercel.app/)

## Docs

[Whitepaper](https://malo-labs.gitbook.io/documentation)

## Malo Labs Invariant Testing Tool

Parse Echidna or Medusa call traces to Foundry test functions with ease.

![Kratos](https://github.com/user-attachments/assets/147d00be-c70e-4fe7-87b0-5143cb82ba45)



## Overview

This project implements smart contracts and decentralized applications using Solidity and modern Web3 development tools.

## Technology Stack

- **Smart Contracts**
- **Development Framework**
- **Testing Tools**: 
  - Foundry Tests
  - Echidna (Fuzzing)
  - Halmos (Formal Verification)
  - Braching Tree Technique
- **Dependencies**:
  - solmate (Optimized contract building blocks)
  - halmos-cheatcodes (Testing utilities)

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- [Node.js](https://nodejs.org/) (v16 or later)
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository with submodules:
```bash
git clone --recursive https://github.com/your-username/Malo-Labs.git
cd Malo-Labs
```

2. Install dependencies:
```bash
forge install
```

3. Build the contracts:
```bash
forge build
```

### Testing

Run the test suite:
```bash
forge test
```

Run fuzzing tests:
```bash
echidna-test .
```
Do not forget to update Foundry regularly with the following command
```
foundryup
```
Similarly for forge-std run

forge update lib/forge-std

Submodules
Run below command to include/update all git submodules like openzeppelin contracts, forge-std etc (lib/)

```
git submodule update --init --recursive
```


## Project Structure

```
contracts/           # Smart contracts
├─ src/             # Source files
├─ test/            # Test files
│  ├─ echidna/      # Fuzzing tests
│  └─ invariants/   # Property-based tests
└─ lib/             # Dependencies
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
