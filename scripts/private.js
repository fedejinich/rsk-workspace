// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const signers = await hre.ethers.getSigners()
    const factory = await hre.ethers.getContractFactory("PrivateBallot")

    const fhBallot = await factory.deploy({ gasLimit: 6000000 })
    console.log("Contract successfully deployed to address:", fhBallot.address);

    const proposals = ["prop1", "prop2", "prop3", "prop4"]

    for (let i = 0; i < proposals.length; i++) {
        const p = proposals[i];
        console.log(`Adding proposal: ${p}`);
        const re = await fhBallot.connect(signers[i])
            .addProposal(p, { gasLimit: 6000000 })
        const re2 = await re.wait()

        try {
            const parsedLog = fhBallot.interface.parseLog(re2.logs[0]);
            console.log(`Event emitted: ${parsedLog.fragment.name}(${parsedLog.args.join(', ')})`);
        } catch (error) {
            console.error("Error decoding log:", error);
        }
    }

    console.log("Waiting for votes...");
    const votes = generateVotes();
    for (let i = 0; i < votes.length; i++) {
        console.log(`Casting vote #${i + 1}`);
        const voteResponse = await fhBallot.connect(signers[i])
            .vote(votes[i], { gasLimit: 6000000 })
        const voteReceipt = await voteResponse.wait()

        try {
            const parsedLog = fhBallot.interface.parseLog(voteReceipt.logs[0]);
            console.log(`Event emitted: ${parsedLog.fragment.name}(${parsedLog.args.join(', ')})`);
        } catch (error) {
            console.error("Error decoding log:", error);
        }
    }

    console.log("Closing ballot and determining the winning proposal...");
    const res = await fhBallot.winner({ gasLimit: 6_800_000 })
    const rec = await res.wait()

    try {
        const parsedLog = fhBallot.interface.parseLog(rec.logs[0]);
        console.log(`Event emitted: ${parsedLog.fragment.name}(${parsedLog.args.join(', ')})`);
    } catch (error) {
        console.error("Error decoding log:", error);
    }
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
