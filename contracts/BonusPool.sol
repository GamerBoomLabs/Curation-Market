//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IContributionPool.sol";
import "./interfaces/IBondingPool.sol";


contract BonusPool is ReentrancyGuard, Ownable {
    bool private isinitialized = false;
    IERC20 public currencyToken;
    IBondingPool public associatedBondingPool;
    IContributionPool public associatedContributionPool;
    
    uint256 private  totalBonusClaimed = 0;
    uint256 private totalContribution;
    uint256 private constant PRECISION = 10**8;
    mapping(address => uint256) private contributionWeight;
    mapping(address => uint256) private bonusClaimed;

    function initialize(
        address _currencyToken,
        address _associatedBondingPool,
        address _associatedContributionPool
    ) external onlyOwner nonReentrant {
        require(!isinitialized, "Pool already initialized");
        require(IContributionPool(_associatedContributionPool).getPoolStatus() == 2, "Contribution pool not completed");

        isinitialized = true;
        currencyToken = IERC20(_currencyToken);
        associatedBondingPool = IBondingPool(_associatedBondingPool);
        associatedContributionPool = IContributionPool(_associatedContributionPool);
        totalContribution = associatedContributionPool.totalContribution();

        for(uint256 i = 0; i <associatedContributionPool.getContributionKeysLength(); i++) {
            address contributorAddr = associatedContributionPool.contributionKeys(i);
            contributionWeight[contributorAddr] = associatedContributionPool.contributions(contributorAddr) * PRECISION / totalContribution;
            bonusClaimed[contributorAddr] = 0;
        }
        
    }

    function claimBonus() external nonReentrant {
        require(contributionWeight[msg.sender] != 0, "Caller not contributor or bonus claimed");
        require(block.timestamp > associatedBondingPool.lastTimestamp(), "Bonus not claimable yet");

        uint256 bonusForContributor = (totalBonusClaimed + currencyToken.balanceOf(address(this))) * contributionWeight[msg.sender] / PRECISION;
        uint256 bonusClaimable = bonusForContributor - bonusClaimed[msg.sender];

        currencyToken.transfer(msg.sender, bonusClaimable);
        bonusClaimed[msg.sender] += bonusClaimable;
        totalBonusClaimed += bonusClaimable;  
    }
}
