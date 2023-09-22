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

    console.log("contract deployed")

    const proposals = ["prop1", "prop2", "prop3", "prop4"]

    for (let i = 0; i < proposals.length; i++) {
        const p = proposals[i];
        console.log("adding proposal: " + p)
        const re = await fhBallot.connect(signers[i])
            .addProposal(p, { gasLimit: 6000000 })
        const re2 = await re.wait()

        try {
            const parsedLog = fhBallot.interface.parseLog(re2.logs[0]);
            console.log("event " + parsedLog.fragment.name + "(" +
                parsedLog.args[0] + ", " + parsedLog.args[1] + ")");
        } catch (error) {
            console.log("Unable to decode log");
        }
    }

    console.log("waiting for votes")
    const votes = generateVotes();
    for (let i = 0; i < votes.length; i++) {
        // for (let i = 0; i < 1; i++) {
        console.log("voting")
        // console.log("encrypted vote [" + votes[i].vote + "]")

        const voteResponse = await fhBallot.connect(signers[i])
            .vote(votes[i], { gasLimit: 6000000 })
        const voteReceipt = await voteResponse.wait()

        try {
            const parsedLog = fhBallot.interface.parseLog(voteReceipt.logs[0]);
            console.log("event " + parsedLog.fragment.name + "(" + parsedLog.args[0] + ")");
        } catch (error) {
            console.log("Unable to decode log");
        }
    }

    console.log("closing ballot")

    // console.log("counting votes")

    // const ok = await fhBallot.voteCount({ gasLimit: 6800000 })

    // console.log(ok)

    console.log("picking winner proposal")

    const res = await fhBallot.winner({ gasLimit: 6_800_000 })

    console.log(res)
    // const receipt2 = await r2.wait()    
    // console.log("winner proposal")
    // const currentTimestampInSeconds = Math.round(Date.now() / 1000);
    // const unlockTime = currentTimestampInSeconds + 60;

    // const lockedAmount = hre.ethers.parseEther("0.001");

    // const lock = await hre.ethers.deployContract("Lock", [unlockTime], {
    //   value: lockedAmount,
    // });
    //
    // await lock.waitForDeployment();
    //
    // console.log(
    //   `Lock with ${ethers.formatEther(
    //     lockedAmount
    //   )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
    // );
}

function generateVotes() {
    const votesJson = require('/Users/fedejinich/Projects/rsk-workspace/scripts/votes.json');

    console.log("generating votes")

    // console.log(votesJson.votesBfv)

    return votesJson.votesPasta
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
