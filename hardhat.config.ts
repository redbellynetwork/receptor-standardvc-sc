import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { config as dotEnvConfig } from "dotenv";

dotEnvConfig({ path: __dirname + "/.env" });

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
      accounts: [`${process.env.PRIVATE_KEY}`],
      url: `${process.env.RPC_URL}`,
      chainId: Number(process.env.CHAIN_ID),
    },
  },
};

export default config;
