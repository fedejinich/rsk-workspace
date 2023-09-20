require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.19",
    networks: {
        hardhat: {},
        regtest: {
            blockGasLimit: 60000000,// Network block gasLimit
            gas: 60000000,
            gasPrice: 0,
            chainId: 33,
            gasMultiplier: 1,
            url: "http://localhost:4444",
            accounts: ["c85ef7d79691fe79573b1a7064c19c1a9819ebdbd1faaab1a8ec92344438aaf4"],
            timeout: 600000000
        }
    }
};
