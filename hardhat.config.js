require("dotenv").config();

require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  solidity: "0.8.10",
  networks: {
    mumbai: {
      chainId: 80001,
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: ["a178130ba7d672cd43056fa3a1188ca2f88a5689741c2901757ed7c98fa49f25"]
    }
  },
  etherscan: {
    apiKey:
    {
      polygonMumbai: "DAM5T1CE98P3AFPMXA3YWS4FN8VRSI1SND"
    }
  }
};
