require('dotenv').config();
const hre = require("hardhat");
const ethers = hre.ethers;
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs');

async function main() {
    const PoolStatus = {
        PENDING: 0,
        FUNDING: 1,
        COMPLETED: 2,
        CANCELLED: 3
    };

    const [owner, receiver1, receiver2, receiver3] = await ethers.getSigners();
    console.log(`Owner: ${owner.address}, Receiver1: ${receiver1.address}, Receiver2: ${receiver2.address}, Receiver3: ${receiver3.address}`);

    const leaves = [owner.address.toLowerCase(), receiver1.address.toLowerCase(), receiver2.address.toLowerCase()].map(ethers.utils.keccak256);
    const tree = new MerkleTree(leaves, keccak256, { sort: true });
    const root = tree.getHexRoot();
    
    console.log(`Merkle Tree Root: ${root}`);

    const deployedAddresses = JSON.parse(fs.readFileSync('deployedAddresses.json'));

    const joyTokenAddress = process.env.LOCAL_JOYTOKEN; 
    const contributionPoolAddress = deployedAddresses.ContributionPool;
    
    const contributionPool = await ethers.getContractAt("ContributionPool", contributionPoolAddress);
    const joyToken = await ethers.getContractAt("IERC20", joyTokenAddress);
    
    const amountToContribute = ethers.utils.parseEther("1"); // 1 JOY
    await contributionPool.connect(owner).startFunding();
    
    // Allow eligible receiver to contribute
    await joyToken.connect(receiver1).approve(contributionPool.address, amountToContribute);
    const proof = tree.getHexProof(ethers.utils.keccak256(receiver1.address.toLowerCase()));
    console.log(`Proof: ${proof}`)

    await contributionPool.connect(receiver1).contribute(amountToContribute, proof);

    const poolBalance = await joyToken.balanceOf(contributionPool.address);
    const receiver1Contribution = await contributionPool.contributions(receiver1.address);
    console.log(`Pool Balance: ${poolBalance.toString()} JOY, Receiver1 Contribution: ${receiver1Contribution.toString()} JOY`);
    
    // Allow another eligible receiver to contribute, potentially exceeding the pool's cap
    const amountToContribute2 = ethers.utils.parseEther("10"); // 10 JOY
    await joyToken.connect(receiver2).approve(contributionPool.address, amountToContribute2);
    const proof2 = tree.getHexProof(ethers.utils.keccak256(receiver2.address.toLowerCase()));
    console.log(`Proof: ${proof2}`)

    await contributionPool.connect(receiver2).contribute(amountToContribute2, proof2);

    const poolBalance2 = await joyToken.balanceOf(contributionPool.address);
    const receiver2Contribution = await contributionPool.contributions(receiver2.address);
    console.log(`Pool Balance: ${poolBalance2.toString()} JOY, Receiver2 Contribution: ${receiver2Contribution.toString()} JOY`);
    
    // If pool status is COMPLETED, transfer the contributions to the bonding pool
    const poolStatus = await contributionPool.getPoolStatus();
    const bondingPoolAddress = deployedAddresses.BondingPool;
    if (poolStatus === PoolStatus.COMPLETED) {
        // Get the balance of the contract
        const contributionPoolBalance = await joyToken.balanceOf(contributionPool.address);
        console.log(`ContributionPool Balance: ${contributionPoolBalance.toString()}`);

        // Get the total contribution amount
        const totalContribution = await contributionPool.totalContribution();
        console.log(`Total Contribution: ${totalContribution.toString()}`);

        const bondingPoolBalanceBefore = await joyToken.balanceOf(bondingPoolAddress);
        console.log(`Bonding Pool Balance before transfer: ${bondingPoolBalanceBefore.toString()} JOY`);

        await contributionPool.connect(owner).transferContributions();

        const bondingPoolBalanceAfter = await joyToken.balanceOf(bondingPoolAddress);
        console.log(`Bonding Pool Balance after transfer: ${bondingPoolBalanceAfter.toString()} JOY`);
    }
    
    // Try to make an ineligible receiver contribute
    await joyToken.connect(receiver3).approve(contributionPool.address, amountToContribute);
    try {
        const invalidProof = []; // Providing an empty proof since receiver3 is not in the whitelist
        await contributionPool.connect(receiver3).contribute(amountToContribute, invalidProof);
    } catch (error) {
        console.error("Expected error:", error);
    }
    
    const receiver3Contribution = await contributionPool.contributions(receiver3.address);
    console.log(`Receiver3 Contribution (Expected 0): ${receiver3Contribution.toString()} JOY`);


    // Deploy BonusFactory
    const BonusFactory = await hre.ethers.getContractFactory("BonusFactory");
    const bonusFactory = await BonusFactory.deploy();

    console.log("BonusFactory deployed to:", bonusFactory.address);

    const poolName = "ExampleBondingPool";
    const poolSymbol = "EBP";

    // Deploy BonusPool through BonusFactory
    await bonusFactory.createContributionBonus(poolName, poolSymbol, joyTokenAddress, deployedAddresses.BondingPool, deployedAddresses.ContributionPool);
    
    const bonusPoolAddress = await bonusFactory.pools(0);

    console.log("BonusPool deployed to:", bonusPoolAddress);

    const BondingPool = await ethers.getContractAt("BondingPool", deployedAddresses.BondingPool);
    await BondingPool.activatePool(bonusPoolAddress);
    console.log("BondingPool activated");

    // Read existing contract addresses
    let data;
    try {
        data = JSON.parse(fs.readFileSync('deployedAddresses.json', 'utf8'));
    } catch (err) {
        console.log('Error reading file from disk:', err);
        return;
    }

    // Add new contract addresses
    data["BonusFactory"] = bonusFactory.address;
    data["BonusPool"] = bonusPoolAddress;

    // Write updated contract addresses back to file
    try {
        fs.writeFileSync('deployedAddresses.json', JSON.stringify(data, null, 4));
    } catch (err) {
        console.log('Error writing file:', err);
    }

}

main().catch(console.error);
