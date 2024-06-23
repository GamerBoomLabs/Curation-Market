require('dotenv').config();
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

async function main() {
  // Fetching accounts from hardhat
  const [deployer] = await hre.ethers.getSigners();
  const joyTokenAddress = process.env.LOCAL_JOYTOKEN; 

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploying BondingCurveCalculator
  const BondingCurveCalculator = await hre.ethers.getContractFactory(
    "BondingCurveCalculator"
  );
  const bondingCurveCalculator = await BondingCurveCalculator.deploy();
  await bondingCurveCalculator.deployed();
  console.log(
    "BondingCurveCalculator deployed to:",
    bondingCurveCalculator.address
  );

  // Deploying BondingFactory
  const BondingFactory = await hre.ethers.getContractFactory("BondingFactory");
  const bondingFactory = await BondingFactory.deploy(bondingCurveCalculator.address);
  await bondingFactory.deployed();
  console.log("BondingFactory deployed to:", bondingFactory.address);
  
  // Set Factory Contract
  await bondingCurveCalculator.setFactoryContract(bondingFactory.address);
  console.log("Factory contract set in BondingCurveCalculator");
  
  // Specify the parameters for createBondingPool function
  const _isContributionNeeded = true;
  const _name = "ExampleBondingPool";
  const _symbol = "EBP";
  const _initialReserveRatio = 5000; 
  const _initialReserve = hre.ethers.utils.parseEther("10"); 
  const _initialBlpMint = hre.ethers.utils.parseEther("1"); 
  const _feeCollector = deployer.address; // Using deployer address as fee collector for this example
  const _currencyToken = joyTokenAddress; // Replace with actual ERC20 token address used as currency token

  // Creating BondingPool
  await bondingFactory.createBondingPool(_isContributionNeeded, _name, _symbol, _initialReserveRatio, _initialReserve, _initialBlpMint, _feeCollector, _currencyToken);
  
  // Get the deployed BondingPool address
  const deployedPoolsCount = await bondingFactory.allPairsLength();
  const bondingPoolAddress = await bondingFactory.pools(deployedPoolsCount - 1);
  console.log("BondingPool deployed to:", bondingPoolAddress);

  const ContributionPool = await hre.ethers.getContractFactory("ContributionPool");
  const ContributionFactory = await hre.ethers.getContractFactory("ContributionFactory");

  // Deploy the ContributionFactory contract
  const contributionFactory = await ContributionFactory.deploy();

  await contributionFactory.deployed();

  console.log("ContributionFactory deployed to:", contributionFactory.address);

  // Now we will create a new ContributionPool contract using the ContributionFactory
  const poolName = "ExampleBondingPool";
  const poolSymbol = "EBP";
  const currencyToken = joyTokenAddress; // this is the address of the currency token in which contributions will be made
  const associatedBondingPoolAddr = bondingPoolAddress; // bondingPoolAddress is the address of the bonding pool created previously.
  const minContribution = ethers.utils.parseEther("0.1"); // The minimum contribution is 0.1 Ether
  const maxContribution = ethers.utils.parseEther("10"); // The maximum contribution is 10 Ether
  const hardcap = ethers.utils.parseEther("10"); // The hardcap is 10 Ether
  
  const [owner, receiver1, receiver2, receiver3] = await ethers.getSigners();
  console.log(`Owner: ${owner.address}, Receiver1: ${receiver1.address}, Receiver2: ${receiver2.address}, Receiver3: ${receiver3.address}`);
  const leaves = [owner.address.toLowerCase(), receiver1.address.toLowerCase(), receiver2.address.toLowerCase()].map(ethers.utils.keccak256);
  const merkleTree = new MerkleTree(leaves, keccak256, { sort: true });
  const root = merkleTree.getHexRoot();
  console.log("Merkle root:", root);

  await contributionFactory.createContributionPool(poolName, poolSymbol, currencyToken, associatedBondingPoolAddr, minContribution, maxContribution, hardcap, root);

  console.log("ContributionPool created.");

  // Let's get the address of the newly created ContributionPool
  const poolCount = await contributionFactory.allPairsLength();

  const newContributionPoolAddress = await contributionFactory.pools(poolCount.toNumber() - 1);

  console.log("New ContributionPool deployed at:", newContributionPoolAddress);

  // Saving deployed contract addresses
  const data = {
    BondingCurveCalculator: bondingCurveCalculator.address,
    BondingFactory: bondingFactory.address,
    BondingPool: bondingPoolAddress,
    ContributionFactory: contributionFactory.address,
    ContributionPool: newContributionPoolAddress,
  };

  fs.writeFileSync("deployedAddresses.json", JSON.stringify(data));
  console.log("Contract addresses saved to deployedAddresses.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
