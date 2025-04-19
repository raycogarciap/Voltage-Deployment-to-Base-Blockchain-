require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-verify");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    base: {
      url: "https://mainnet.base.org",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 8453
    }
  },
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_API_KEY
    }
  }
};
