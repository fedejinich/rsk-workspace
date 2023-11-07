// will compile your contracts, add the hardhat runtime environment's members to the
// we require the hardhat runtime environment explicitly here. this is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// you can also run a script with `npx hardhat run <script>`. if you do that, hardhat
// global scope, and execute the script.
// const hre = require("hardhat");
const hre = require('hardhat');
const fs = require('fs');
const ethUtil = require('ethereumjs-util');
const { bigIntToUnpaddedBytes } = require('@ethereumjs/util');
const LegacyTransaction = require('@ethereumjs/tx').LegacyTransaction
const axios = require('axios');
const bytesToHex = require("@ethereumjs/util").bytesToHex

async function main() {
    const benchmarks = [];

    const signers = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("PrivateBallot2");

    // const startdeploy = date.now();
    const fhBallot = await factory.deploy({ gasLimit: 6_000_000 });
    await fhBallot.waitForDeployment()
    // console.log(a)
    // const deploytime = date.now() - startdeploy;
    // const deploygas = a.gasused.tonumber();
    // benchmarks.push({ operation: 'deploy', time: deploytime });//, gas: deploygas });
    console.log("contract successfully deployed to address:", await fhBallot.getAddress());

    const proposals = ["prop1", "prop2", "prop3", "prop4"];

    for (let i = 0; i < proposals.length; i++) {
        const p = proposals[i];

        console.log(`casting proposal #${i + 1}`);
        console.log(`signer addr ` + await signers[i].getAddress())

        const startAddProposal = Date.now();

        // add a new proposal by address
        const re = await fhBallot.connect(signers[i]).addProposal(p, { gasLimit: 6_000_000 });

        const addProposalTime = Date.now() - startAddProposal;
        const addProposalReceipt = await re.wait();
        const addProposalGas = addProposalReceipt.gasUsed
        benchmarks.push({ operation: `addProposal`, time: addProposalTime, gas: addProposalGas });

        // parse log
        try {
            const parsedLog = fhBallot.interface.parseLog(addProposalReceipt.logs[0]);
            console.log(`event emitted: ${parsedLog.fragment.name}(${parsedLog.args.join(', ')})`);
        } catch (error) {
            console.error("error decoding log:", error);
        }
    }

    console.log("waiting for votes...");
    const votes = generateVotes();
    for (let i = 0; i < votes.length; i++) {
        const startVote = Date.now()

        console.log(`casting vote #${i + 1}`);

        // new vote
        const ballotAddr = await fhBallot.getAddress()
        const voteTxHash = await sendEncryptedTransaction(signers[i],
            ballotAddr, [votes[i]])

        // todo(fedejinich) this should be removed
        if (voteTxHash == null) {
            console.log("vote txHash shoudln't be null")
            process.exit()
        }

        // console.log("fetching receipt")
        // let voteReceipt
        // while(voteReceipt == undefined || voteReceipt == null) {
        //     voteReceipt = await hre.ethers.
        //         provider.getTransactionReceipt(voteTxHash)
        // }
        // console.log("receipt")
        // console.log(voteReceipt)

        const voteTime = Date.now() - startVote
        const voteReceipt = await hre.ethers.provider
            .getTransactionReceipt(voteTxHash)

        if (voteReceipt == null) {
            console.log("vote receipt shouldn't be null")
            process.exit()
        }

        const voteGas = voteReceipt.gasUsed
        benchmarks.push({ operation: `vote`, time: voteTime, gas: voteGas })

        // parse log
        try {
            const parsedLog = fhBallot.interface.parseLog(voteReceipt.logs[0]);
            console.log(`event emitted: ${parsedLog.fragment.name}(${parsedLog.args.join(', ')})`);
        } catch (error) {
            console.error("error decoding log:", error);
        }
    }

    console.log("closing ballot")

    const startClose = Date.now();

    // close ballot
    const res0 = await fhBallot.closeBallot({ gasLimit: 6_800_000 });
    const closeTime = Date.now() - startClose;
    const closeGas = (await res0.wait()).gasUsed
    benchmarks.push({ operation: 'closeballot', time: closeTime, gas: closeGas });

    console.log("determining the winning proposal...");

    const startWinner = Date.now();

    // pickup winner
    const res = await fhBallot.winner2({ gasLimit: 6_800_000 });

    const winnerTime = Date.now() - startWinner;
    const rec = await res.wait()
    const winnerGas = rec.gasUsed
    benchmarks.push({ operation: 'determinewinner', time: winnerTime, gas: winnerGas });

    // parse log
    try {
        const parsedLog = fhBallot.interface.parseLog(rec.logs[0]);
        console.log(`event emitted: ${parsedLog.fragment.name}(${parsedLog.args.join(', ')})`);
    } catch (error) {
        console.error("error decoding log:", error);
    }

    // generate csv content
    const csvContent = "operation,time (ms),gas\n" + benchmarks.map(b => `${b.operation},${b.time},${b.gas}`).join("\n");

    // write csv to file
    fs.writeFileSync('benchmark2_results.csv', csvContent);
}

function generateVotes() {
    const votesJson = require('/Users/fedejinich/Projects/rsk-workspace/scripts/votes.json');

    return votesJson.votesPasta
}

const { Common } = require('@ethereumjs/common')
async function sendEncryptedTransaction(signer, toAddr, encryptedParams) {
    const fromPk = cowPrivateKey(signer.address)
    // const wallet = new ethers.Wallet("0x" + fromPk, provider);
    const nonce = await hre.ethers.provider.getTransactionCount(signer.address)
    const txData = {
        from: signer.address,
        to: toAddr,
        value: hre.ethers.toBeHex(0),
        nonce: nonce,
        data: "0xa24a4e88", // no data needed
        gasLimit: hre.ethers.toBeHex(6_800_000), //2100),
        gas: hre.ethers.toBeHex(6_800_000),
        gasPrice: hre.ethers.toBeHex(0),
        chainId: hre.ethers.toBeHex(33)
    }
    // const sTx = await wallet.signTransaction(txData)

    // const common = new Common({ chain: 33 })
    const ops = Common.custom({ chainId: 33 })
    const tx = LegacyTransaction.fromTxData(txData, ops)
    const txSigned = tx.sign(ethUtil.toBuffer("0x" + fromPk))
    const txBytes = txSigned.serialize()

    const txHex = bytesToHex(txBytes)

    const epRes = ethUtil.rlp.encode(encryptedParams[0])
    const epResHex = bytesToHex(epRes)

    const encryptedTx = ethUtil.rlp.encode([txHex, epResHex])
    const encryptedTxHex = bytesToHex(encryptedTx)

    try {
        const payloadTx = Object.assign({}, {}, {
            jsonrpc: '2.0',
            method: 'eth_sendEncryptedTransaction',
            params: [encryptedTxHex],
            id: '1'
        })
        const res = await axios({
            url: "http://localhost:4444",
            method: 'POST',
            data: payloadTx,
            headers: { 'Content-Type': 'application/json' }
        })

        const txHash = res.data.result

        console.log('tx hash ' + txHash)

        return txHash
    } catch (error) {
        console.error('error sending encrypted transaction:', error)
    }
}

function cowPrivateKey(addr) {
    const accounts = ["c85ef7d79691fe79573b1a7064c19c1a9819ebdbd1faaab1a8ec92344438aaf4", // cow
        "0c06818f82e04c564290b32ab86b25676731fc34e9a546108bf109194c8e3aae", // cow1
        "88fcad7d65de4bf854b88191df9bf38648545e7e5ea367dff6e025b06a28244d",
        "1786958bf8781c0047f94c9bd7e39402cdadebef6f8faca6b503b991814f5e75",
        "3927ff59ac5da854e7633682792aae26e8f83b515c3c6dc7520b5733d4588b8a",
        "20e4a6381bd3826a14f8da63653d94e7102b38eb5f929c7a94652f41fa7ba323",
        "c1783a9a8222e47778911c58bb5aac1343eb425159ff140799e0a283bfb8fa16",
        "e88b7bfb0b3ffe2245e3293e20901022ea01ebc19898dfe468289c9a07672627",
        "d77b8a342be95c5c31fa85c20450b424663c4fb4a499cfc80c202c592c85c219",
        "082f57b8084286a079aeb9f2d0e17e565ced44a2cb9ce4844e6d4b9d89f3f595", // cow9
    ]
    const privateKeyToAddress = privateKeyHex => {
        const privateKeyBuffer = Buffer.from(privateKeyHex.slice(0), 'hex');
        const publicKeyBuffer = ethUtil.privateToPublic(privateKeyBuffer);
        const addressBuffer = ethUtil.publicToAddress(publicKeyBuffer);
        return ethUtil.bufferToHex(addressBuffer);
    }
    const accountsMap = {}
    accounts.forEach(priv => accountsMap[privateKeyToAddress(priv)] = priv)
    const cowPrivateKey = accountsMap[addr.toLowerCase()]

    if (cowPrivateKey == null) {
        console.log("privte key not found")
        console.log(accountsMap)
        console.log(addr.toLowerCase())
        process.exit()
    }

    return cowPrivateKey
}

// we recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

