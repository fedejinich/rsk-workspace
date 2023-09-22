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
            accounts: ["c85ef7d79691fe79573b1a7064c19c1a9819ebdbd1faaab1a8ec92344438aaf4", // cow
                "0c06818f82e04c564290b32ab86b25676731fc34e9a546108bf109194c8e3aae", // cow1
                "88fcad7d65de4bf854b88191df9bf38648545e7e5ea367dff6e025b06a28244d",
                "1786958bf8781c0047f94c9bd7e39402cdadebef6f8faca6b503b991814f5e75",
                "3927ff59ac5da854e7633682792aae26e8f83b515c3c6dc7520b5733d4588b8a",
                "20e4a6381bd3826a14f8da63653d94e7102b38eb5f929c7a94652f41fa7ba323",
                "c1783a9a8222e47778911c58bb5aac1343eb425159ff140799e0a283bfb8fa16",
                "e88b7bfb0b3ffe2245e3293e20901022ea01ebc19898dfe468289c9a07672627",
                "d77b8a342be95c5c31fa85c20450b424663c4fb4a499cfc80c202c592c85c219",
                "082f57b8084286a079aeb9f2d0e17e565ced44a2cb9ce4844e6d4b9d89f3f595", // cow9
            ],
            timeout: 900000000000
        }
    }
};
