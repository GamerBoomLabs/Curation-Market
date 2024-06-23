require('dotenv').config();
const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require('fs');

async function main() {
    const [owner, user1, user2] = await ethers.getSigners();

    const deployedAddresses = JSON.parse(fs.readFileSync('deployedAddresses.json'));
    const bondingPoolAddress = deployedAddresses.BondingPool; 

    const joyTokenAddress = process.env.LOCAL_JOYTOKEN; 
    const joyToken = await ethers.getContractAt("IERC20", joyTokenAddress);

    const bondingPool = await ethers.getContractAt("BondingPool", bondingPoolAddress);

    // Assume that owner has a lot of JOY tokens.
    // Let's start with the user1 minting some BLP tokens.

    let user1BLPBeforeMint = await bondingPool.balanceOf(user1.address);
    let user1JOYBeforeMint = await joyToken.balanceOf(user1.address);
    console.log(`User1 BLP before mint: ${ethers.utils.formatEther(user1BLPBeforeMint)}`);
    console.log(`User1 JOY before mint: ${ethers.utils.formatEther(user1JOYBeforeMint)}`);

    await joyToken.connect(user1).approve(bondingPoolAddress, ethers.utils.parseEther("5"));
    await bondingPool.connect(user1).mint(ethers.utils.parseEther("5"));

    let user1BLPAfterMint = await bondingPool.balanceOf(user1.address);
    let user1JOYAfterMint = await joyToken.balanceOf(user1.address);
    console.log(`User1 BLP after mint: ${ethers.utils.formatEther(user1BLPAfterMint)}`);
    console.log(`User1 JOY after mint: ${ethers.utils.formatEther(user1JOYAfterMint)}`);

    // Then, let's make user1 burn some BLP tokens.

    let user1BLPBeforeBurn = await bondingPool.balanceOf(user1.address);
    console.log(`User1 BLP before burn: ${ethers.utils.formatEther(user1BLPBeforeBurn)}`);

    await bondingPool.connect(user1).burn(ethers.utils.parseEther("0.15"));

    let user1BLPAfterBurn = await bondingPool.balanceOf(user1.address);
    console.log(`User1 BLP after burn: ${ethers.utils.formatEther(user1BLPAfterBurn)}`);

    // Next, owner adds some reserave to the pool.
    await joyToken.connect(owner).approve(bondingPoolAddress, ethers.utils.parseEther("2"));
    await bondingPool.connect(owner)._addReserve(ethers.utils.parseEther("2"));

    // Owner distributes fees. This can only be done once every EPOCHDURATION.
    await hre.network.provider.send("evm_increaseTime", [28 * 24 * 60 * 60]); // Increase time by 28 days.
    await hre.network.provider.send("evm_mine"); // Mine the next block so the timestamp takes effect.
    await bondingPool.connect(owner).distributeFees();

    // Owner enables transfers.
    await bondingPool.connect(owner).manageTransfer(true);

    // User1 tries to transfer some BLP to user2.
    await bondingPool.connect(user1).transfer(user2.address, ethers.utils.parseEther("0.01"));

    // Finally, owner closes the pool.
    await bondingPool.connect(owner).closePool();

    console.log("Tests passed.");
}

main().catch(console.error);
