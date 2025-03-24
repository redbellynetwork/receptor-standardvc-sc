import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "shanghai",
    },
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 20000, // Increase the timeout value if needed
  },
  defaultNetwork: "local",
  networks: {
    hardhat: {
      chainId: 31337,
      blockGasLimit: 0x1fffffffffffff,
    },
    local: {
      accounts: ["0x1f36dd877bfa8a8946ed49441b7767db5cddc0d82822641335c483ba7760abb5"],
      url: "http://localhost:8545",
      chainId: 161,
    },
  },
};

export default config;
