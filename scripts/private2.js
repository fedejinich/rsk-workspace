// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
// const hre = require("hardhat");
const hre = require('hardhat');
const fs = require('fs');

async function main() {
    const benchmarks = [];

    const signers = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("PrivateBallot2");

    // const startDeploy = Date.now();
    const fhBallot = await factory.deploy({ gasLimit: 6_000_000 });
    await fhBallot.waitForDeployment()
    // console.log(a)
    // const deployTime = Date.now() - startDeploy;
    // const deployGas = a.gasUsed.toNumber();
    // benchmarks.push({ operation: 'Deploy', time: deployTime });//, gas: deployGas });
    console.log("Contract successfully deployed to address:", fhBallot.address);

    console.log("Waiting for votes...");
    const proposals = ["prop1", "prop2", "prop3", "prop4"];

    for (let i = 0; i < proposals.length; i++) {
        const p = proposals[i];

        console.log(`Casting vote #${i + 1}`);

        const startAddProposal = Date.now();
        const re = await fhBallot.connect(signers[i]).addProposal(p, { gasLimit: 6_000_000 });
        const addProposalTime = Date.now() - startAddProposal;
        const addProposalReceipt = await re.wait();
        const addProposalGas = addProposalReceipt.gasUsed
        benchmarks.push({ operation: `AddProposal`, time: addProposalTime, gas: addProposalGas });

        try {
            const parsedLog = fhBallot.interface.parseLog(addProposalReceipt.logs[0]);
            console.log(`Event emitted: ${parsedLog.fragment.name}(${parsedLog.args.join(', ')})`);
        } catch (error) {
            console.error("Error decoding log:", error);
        }
    }

    const votes = generateVotes();
    for (let i = 0; i < votes.length; i++) {

        const startVote = Date.now()
        const voteResponse = await fhBallot.connect(signers[i]).vote(votes[i], { gasLimit: 6_000_000 })
        const voteTime = Date.now() - startVote
        const voteReceipt = await voteResponse.wait()
        const voteGas = voteReceipt.gasUsed
        benchmarks.push({ operation: `Vote`, time: voteTime, gas: voteGas })

        try {
            const parsedLog = fhBallot.interface.parseLog(voteReceipt.logs[0]);
            console.log(`Event emitted: ${parsedLog.fragment.name}(${parsedLog.args.join(', ')})`);
        } catch (error) {
            console.error("Error decoding log:", error);
        }
    }

    console.log("Closing ballot")

    const startClose = Date.now();
    const res0 = await fhBallot.closeBallot({ gasLimit: 6_800_000 });
    const closeTime = Date.now() - startClose;
    const closeGas = (await res0.wait()).gasUsed
    benchmarks.push({ operation: 'CloseBallot', time: closeTime, gas: closeGas });

    console.log("Determining the winning proposal...");

    const startWinner = Date.now();
    const res = await fhBallot.winner({ gasLimit: 6_800_000 });
    const winnerTime = Date.now() - startWinner;
    const rec = await res.wait()
    const winnerGas = rec.gasUsed
    benchmarks.push({ operation: 'DetermineWinner', time: winnerTime, gas: winnerGas });

    try {
        const parsedLog = fhBallot.interface.parseLog(rec.logs[0]);
        console.log(`Event emitted: ${parsedLog.fragment.name}(${parsedLog.args.join(', ')})`);
    } catch (error) {
        console.error("Error decoding log:", error);
    }

    // generate CSV content
    const csvContent = "Operation,Time (ms),Gas\n" + benchmarks.map(b => `${b.operation},${b.time},${b.gas}`).join("\n");

    // write CSV to file
    fs.writeFileSync('benchmark_results.csv', csvContent);
}

function generateVotes() {
    const votesJson = require('/Users/fedejinich/Projects/rsk-workspace/scripts/votes.json');

    return votesJson.votesPasta
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
