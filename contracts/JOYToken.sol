//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract JOYToken is ERC20, Ownable, Pausable {

    bool private mintingEnabled = false;
    bool private halvingActivated = false;
    uint8 public epochsSinceLastHalving = 0;
    uint16 public feeRatio = 5; // // 5 basis points = 0.05%
    uint256 public constant EPOCHDURATION = 28 days;
    uint256 public constant MAX_SUPPLY = 210000000000 * 10**18;
    uint256 public constant INITIAL_EPOCH_REWARD = 2500000000 * 10**18;
    
    uint256 public startTimestamp; //The block height at which the epoch begins
    uint256 public currentEpochReward = INITIAL_EPOCH_REWARD;
    
    mapping(address => bool) public blacklists;

    constructor() ERC20("JOYToken", "JOY") {
        _mint(msg.sender, (MAX_SUPPLY * 5) / 100); // 5% of total supply
    }

    // Function to activate the halving
    function activateHalving() external onlyOwner {
        require(!halvingActivated, "Halving already activated");
        mintingEnabled = true;
        startTimestamp = block.timestamp;
        halvingActivated = true;
    }

    function blacklist(address _address, bool _isBlacklisted) external onlyOwner {
        require(_address != owner(), "Owner can't be balcklisted");
        blacklists[_address] = _isBlacklisted;
    }

    function mint() external onlyOwner {
        require(halvingActivated && mintingEnabled, "Minting paused or bot enabled");
        require(block.timestamp >= startTimestamp + uint256(EPOCHDURATION) && block.timestamp < startTimestamp + uint256(EPOCHDURATION) * 2, "Current epoch not over yet");
        uint256 currentSupply = totalSupply();
        require(MAX_SUPPLY >= currentSupply + currentEpochReward, "Mint amount exceeds max supply");

        _mint(msg.sender, currentEpochReward);

        epochsSinceLastHalving += 1;
        if (epochsSinceLastHalving == 6) {
            currentEpochReward = currentEpochReward / 2;
            epochsSinceLastHalving = 0;
        }

        startTimestamp = startTimestamp + uint256(EPOCHDURATION);
        
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 feeAmount = (amount * feeRatio) / 10000;
        uint256 netAmount = amount - feeAmount;

        super._transfer(sender, recipient, netAmount);

        // Accumulate the fee amount in the contract's balance
        super._transfer(sender, address(this), feeAmount);
    }
    
    //Override the _beforeTokenTransfer function to include the pause check and blacklist check
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
        require(!paused(), "Token transfer service paused");
        super._beforeTokenTransfer(from, to, amount);
    }

    function setFeeRatio(uint16 _feeRatio) external onlyOwner {
        require(_feeRatio <= 10000, "Invalid fee ratio");
        feeRatio = _feeRatio;
    }

    function withdrawFees() external onlyOwner {
        require(msg.sender == owner(), "Invalid caller");
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "No fees to withdraw");
        _transfer(address(this), msg.sender, balance);
    }

    function manageMinting(bool _MintingEnabled) external onlyOwner {
        mintingEnabled = _MintingEnabled;
    }

    //Function to pause token tansfer
    function pause() external onlyOwner {
        _pause();
    }

    //Function to unpause token transfer
    function unpause() external onlyOwner {
        _unpause();
    }
}

