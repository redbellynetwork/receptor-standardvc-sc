# Receptor Verifier Standard Smart Contracts and Interfaces

This repository contains a collection of Receptor Verifier standard smart contracts and interfaces designed for Ethereum-based blockchain applications. Developers can use this base contract package to extend VCVerifierBase contract to verify ED25519 signed credentials issued by IDP and can implement `_postVerification` method that what they need to do after verifcation.

### Table of Contents

- [Pre-requisites](#pre-requisites)
- [How to Install](#how-to-install)
- [How to Run](#how-to-run)
  - [Compile Contracts and Libraries](#compile-contracts-and-libraries)
  - [Testing Upgradeable Smart Contracts](#testing-upgradeable-smart-contracts)
  - [Clean Typechain Types and Artifacts](#clean-typechain-types-and-artifacts)
- [Publishing the Package](#publishing-the-package)
- [Installation Package](#installation-package)

### Pre-requisites

Before you start, make sure your development environment meets the following requirements:

1. Node.js version 20+
   This project requires Node.js 20 or higher. You can use nvm to manage your Node.js versions:

- `nvm install 20`
- `nvm use 20`
- `node -v` # Verify node version

2. Solidity Compiler Version 0.8.22
   Ensure you are using Solidity compiler version 0.8.22 for compatibility with the smart contracts in this repository.

### How to Install

- Install Dependencies
  Run the following command to install the necessary dependencies:
  `npm i`

  This will install the dependencies listed in package.json, including Hardhat, Prettier, and other essential packages.

### How to Run

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

#### 3. Clean Typechain Types and Artifacts

To clean up generated artifacts and Typechain types, you can run the following command:

`npx hardhat clean`
This will remove all build artifacts and type definitions, allowing you to start fresh with new builds.

### Publishing the Package

If you’re contributing to the repository or need to publish a new version, follow these steps to release and publish the package to GitHub Packages.

1. Update the Version
   Update the version in package.json to match your desired release version. A proper versioning scheme (e.g., 0.0.3, 1.0.0, etc.) should be followed.

2. Run the Publish Workflow
   Once the version is updated, you can trigger the GitHub Actions workflow to publish the package. The workflow will:

   - Create a Git tag based on the version

   - Generate a changelog based on commits

   - Create a GitHub release

   - Publish the package to GitHub Packages

   To manually trigger the workflow:

   - Navigate to the Actions tab of this repository on GitHub.

   - Find the create-publish-release workflow.

   - Click on Run workflow to trigger the process.

   - This will automatically handle tagging, changelog creation, and publishing the new version to GitHub Packages.

### Additional Notes

GitHub Packages Authentication: Ensure you have your GitHub token set up to authenticate with GitHub Packages. You can set this in your .npmrc file in place of field GITHUB_TOKEN

Solidity Versioning: If you need to work with a different Solidity version, make sure to adjust the version in hardhat.config.ts to reflect the correct version.

## Installation Package

- Install the Package from GitHub Packages
  To install this package in your project, simply run the following command using npm:

  `npm install @redbellynetwork/receptor-standardvc-sc`

  This command will install the latest version of the @redbellynetwork/receptor-standardvc-sc package from GitHub Packages, where it's hosted. Ensure your project is configured to access GitHub Packages via authentication using a valid GitHub token. This can be done by adding the appropriate .npmrc file in your project directory.

- You can use this in your contract in this way

```solidity
pragma solidity 0.8.22;

import { VCVerifierBaseContract } from "@redbellynetwork/receptor-standardvc-sc/contracts/verifier/VCVerifierBase.sol";

contract MyVerifierContract is VCVerifierBaseContract {
  constructor(string memory _credentialType) VCVerifierBaseContract(_credentialType) {}
}
```
