// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const factory = await hre.ethers.getContractFactory("PrivateBallot")
    const fhBallot = await factory.deploy({ gasLimit: 6000000 })

    console.log("contract deployed")

    const proposals = ["prop1", "prop2", "prop3", "prop4"]

    for (const p in proposals) {
        console.log("adding proposal: " + p)
        await fhBallot.addProposal(p, { gasLimit: 6000000 })
    }

    console.log("waiting for votes")
    for (const v of generateVotes()) {
        console.log("voting")
        console.log(v)

        const r = await fhBallot.vote(v, {gasLimit:6000000})
        await r.wait() 
    }

    console.log("closing ballot")
    
    // console.log("counting votes")
    
    //const r1 = await fhBallot.voteCount()
    //const rec1 = await r1.wait()
    
    // console.log("picking winner proposal")
    
    // const r2 = await pb.winner()
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
