//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IContributionPool.sol";

contract ContributionPool is IContributionPool, Ownable, ReentrancyGuard {
    enum PoolStatus { PENDING, FUNDING, COMPLETED, CANCELLED }
    
    bool private initialized = false;
    PoolStatus public poolStatus;
    mapping(address => uint256) public contributions;
    address[] public contributionKeys;
    uint256 public totalContribution;
    
    uint256 private minContribution;
    uint256 private maxContribution;
    uint256 private hardcap;
    bytes32 private root;
    mapping(address => bool) private hasContributed; 
    address private associatedBondingPoolAddr;
    IERC20 private currencyToken;

    function initialize(
        IERC20 _currencyToken,
        address _associatedBondingPoolAddr,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _hardcap,
        bytes32 _root
    ) external onlyOwner {
        require(!initialized, "Contract already initialized");
        initialized = true;

        currencyToken = _currencyToken;
        associatedBondingPoolAddr = _associatedBondingPoolAddr;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        hardcap = _hardcap;
        root = _root;
        totalContribution = 0;
        poolStatus = PoolStatus.PENDING;
    }

    function contribute(uint256 _amount, bytes32[] calldata _merkleProof) external nonReentrant {
        require(!hasContributed[msg.sender], "Address already contributed");
        require(poolStatus == PoolStatus.FUNDING, "Pool not being funding");
        require(_amount >= minContribution && _amount <= maxContribution, "Contribution exceeds limit");
        require(currencyToken.balanceOf(msg.sender) >= _amount, "Insufficient Joy balance");

        // Verify the user's Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, root, leaf),
            "Not in the whitelist"
        );

        currencyToken.transferFrom(msg.sender, address(this), _amount);
        hasContributed[msg.sender] = true; 
        contributions[msg.sender] = _amount;
        totalContribution += _amount;
        contributionKeys.push(msg.sender);
        
        if (totalContribution >= hardcap) {
            poolStatus = PoolStatus.COMPLETED;
        }  
    }

    //Transfer total contributions to the associated bonding pool for the initial reserve
    function transferContributions() external onlyOwner nonReentrant {
        require(poolStatus == PoolStatus.COMPLETED, "Pool not completed");
        require(associatedBondingPoolAddr != address(0),"Invalid bondingFactory address");

        currencyToken.transfer(associatedBondingPoolAddr, currencyToken.balanceOf(address(this)));
    }

    function claimRefund() external nonReentrant {
        require(poolStatus == PoolStatus.CANCELLED, "Pool not cancelled");
        require(contributions[msg.sender] != 0, "Caller not contributor or refund claimed");
        currencyToken.transferFrom(address(this), msg.sender, contributions[msg.sender]);
        contributions[msg.sender] =0;
    }

    function startFunding() external onlyOwner nonReentrant {
        poolStatus = PoolStatus.FUNDING;
    }

    function cancelContributionPool() external onlyOwner nonReentrant {
        poolStatus = PoolStatus.CANCELLED;
    }

    function getPoolStatus() external view returns (uint8) {
        return uint8(poolStatus);
    }

    function getContributionKeysLength() external view returns (uint256) {
        return contributionKeys.length;
    }
}
