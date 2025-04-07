# Receptor Verifier Standard Smart Contracts and Interfaces

This repository contains a collection of Receptor Verifier standard smart contracts and interfaces designed for Ethereum-based blockchain applications. Developers can use this base contract package to extend VCVerifierBase contract to verify ED25519 signed credentials issued by IDP and can implement `_postVerification` method that what they need to do after verifcation.

## Installation Package

- Install the Package from GitHub Packages

  Create `.npmrc` in your project

  ```
  @redbellynetwork:registry=https://npm.pkg.github.com
  //npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}
  always-auth=true
  ```

  Obtains Github Token from this [instruction](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) and ensure `Read Package` as one of the permission

  To install this package in your project, simply run the following command using npm:

  ```bash
  npm install @redbellynetwork/receptor-standardvc-sc
  ```

- You can use this in your contract in this way

```solidity
pragma solidity 0.8.22;

import { VCVerifierBaseContract } from "@redbellynetwork/receptor-standardvc-sc/contracts/verifier/VCVerifierBase.sol";

contract MyVerifierContract is VCVerifierBaseContract {
  constructor(string memory _credentialType) VCVerifierBaseContract(_credentialType) {}
}
```

## Development and local run

#### Installations and run example

- Require NodeJS version 20+

  - `nvm install 20`
  - `nvm use 20`

- Require Solidity compiler version 0.8.22

#### 1. Compile Contracts and Libraries

    To compile the smart contracts and any associated libraries, use the following command:
    `npm run compile`

    This will trigger the hardhat compile command and compile all the Solidity files in the contracts/ directory.

#### 2. Testing Upgradeable Smart Contracts

You can test your smart contracts by running a local test chain and executing unit tests. Follow these steps:

- Build the Local Chain
  To run a local blockchain instance (via Hardhat) to test the contracts, run the buildChain task:
  `task buildChain`

- Run Unit Tests
  You can execute unit tests for the contracts using Hardhat’s testing framework:
  `npm run test`
  This will run all tests located in the test/ directory and display the results in your terminal.

  GitHub Packages Authentication: Ensure you have your GitHub token set up to authenticate with GitHub Packages. You can set this in your .npmrc file in place of field GITHUB_TOKEN
