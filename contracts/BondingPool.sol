//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBondingCurveCalculator.sol";
import "./interfaces/IBondingPool.sol";

contract BondingPool is ERC20, Ownable, ReentrancyGuard {
    enum PoolStatus {PENDING, OPEN, CLOSED}

    bool private isTransferEnabled = false;
    bool private initialized = false;
 
    uint16 private mintFeeRatio = 50;
    uint16 private burnFeeRatio = 50;
    uint16 private bonusRatio = 500;
    uint256 public initialBlpMint;
    uint256 public initialReserve;
    uint256 public constant EPOCHDURATION = 28 days;
    uint256 public constant PRECISION = 10**4;
    uint256 public feeForContributorsLast;
    uint256 public lastTimestamp;
    uint256 public reserveRatio;//The reserve ratio K of bonding pool
    uint256 private accumulatedFees = 0;
    
    IERC20 private currencyToken;
    IBondingCurveCalculator private bondingCurveCalculator;
    address private associatedBunusPoolAddr;

    PoolStatus public poolStatus;
    
    
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function initialize(
        bool _isContributionNeeded,
        address _feeCollector, 
        IERC20 _currencyToken,
        IBondingCurveCalculator _bondingCurveCaculator,
        uint256 _initialReserveRatio,
        uint256 _initialReserve,
        uint256 _initialBlpMint
    ) external onlyOwner {
        require(!initialized, "Contract already initialized");
        require(_initialReserveRatio >= (PRECISION / 2) && _initialReserveRatio <= PRECISION, "K being outside of range"); //Check the range of inputs 
        require(_initialReserve != 0 && _initialBlpMint != 0, "Invalid initialization parameter");    
        
        initialized = true;
        currencyToken = _currencyToken;
        bondingCurveCalculator = _bondingCurveCaculator;
        
        initialBlpMint = _initialBlpMint;
        initialReserve =_initialReserve;

        reserveRatio = _initialReserveRatio; // The ratio values below are scaled up by 10,000 to avoid precision loss.

        if(!_isContributionNeeded) {
        // Permanently Lock the initial reserve as the minimum liquidity
        _mint(address(this), _initialBlpMint); 
        _burn(address(this), _initialBlpMint); 
        lastTimestamp = block.timestamp;
        poolStatus = PoolStatus.OPEN;
        associatedBunusPoolAddr = address(0);
        }else {
           poolStatus = PoolStatus.PENDING; 
        }

         // Transfer the ownership from factory contract to owner's account
        transferOwnership(_feeCollector);   
        }
    
    function activatePool(address _associatedBunusPoolAddr) external onlyOwner nonReentrant {
        require(poolStatus == PoolStatus.PENDING, "Pool not created or already activated");
        require(currencyToken.balanceOf(address(this)) >= initialReserve, "Insufficient initial reserve");
        
        // Permanently Lock the initial reserve as the minimum liquidity
        _mint(address(this), initialBlpMint); 
        _burn(address(this), initialBlpMint); 

        associatedBunusPoolAddr = _associatedBunusPoolAddr;
        lastTimestamp = block.timestamp;
        poolStatus = PoolStatus.OPEN;
    }

    function setFeeRatios(uint16 _mintFeeRatio, uint16 _burnFeeRatio, uint16 _bonusRatio) external onlyOwner nonReentrant {
        require(_mintFeeRatio < PRECISION && _burnFeeRatio < PRECISION && _bonusRatio < PRECISION, "Above max limit");
        mintFeeRatio = _mintFeeRatio;
        burnFeeRatio = _burnFeeRatio;
        bonusRatio = _bonusRatio;
    }

    function mint(uint256 currencyAmount) external nonReentrant {
        require(poolStatus == PoolStatus.OPEN, "Pool not open");
        require(currencyAmount != 0 && currencyToken.balanceOf(msg.sender) >= currencyAmount, "Insufficient currency token balance");
        
        // Save the supply and reserve data of pool before transfer
        uint256 R0 = currencyToken.balanceOf(address(this));
        uint256 S0 = totalSupply() + initialBlpMint;
        require((R0 != 0) && (S0 != 0), "Insufficient liquidity");
        currencyToken.transferFrom(msg.sender, address(this), currencyAmount);
        uint256 mintFee = currencyAmount * mintFeeRatio / PRECISION;
        currencyAmount = currencyToken.balanceOf(address(this)) - R0 - mintFee;
        uint256 blpAmount = bondingCurveCalculator.calculateShareMinted(S0, currencyAmount, R0, reserveRatio, PRECISION);
        _mint(msg.sender, blpAmount);

        //Accumulate fees
        accumulatedFees += mintFee;
    }

    function burn(uint256 blpAmount) external nonReentrant {
        require(poolStatus == PoolStatus.OPEN, "Pool not open");
        require(balanceOf(msg.sender) >= blpAmount && blpAmount != 0, "Insufficient BLP balance");

        //Save the supply and reserve data of pool before burning
        uint256 R0 = currencyToken.balanceOf(address(this));
        uint256 S0 = totalSupply() + initialBlpMint;
        require(R0 != 0 && S0 != 0, "Insufficient liquidity");
        _burn(msg.sender, blpAmount);
        uint256 currencyAmount = bondingCurveCalculator.calculateReserveRedeemed(S0, blpAmount, R0, reserveRatio, PRECISION);
        uint256 burnFee = currencyAmount * burnFeeRatio / PRECISION;
        uint256 userAmount = currencyAmount - burnFee;
        currencyToken.transfer(msg.sender, userAmount);
        
        //Accumulate fees
        accumulatedFees += burnFee;
    }

    function _addReserve(uint256 currencyAmount) external onlyOwner nonReentrant {
        require(poolStatus == PoolStatus.OPEN, "Pool not open");
        require(reserveRatio >= (PRECISION / 2) && reserveRatio <= PRECISION, "K being outside of range"); //Check the range of K value before adding reserve
        require(currencyAmount != 0, "Invalid amount");

        uint256 R0 = currencyToken.balanceOf(address(this));
        // Add JoyToken reserve to the contract
        require(currencyToken.transferFrom(msg.sender, address(this), currencyAmount), "JoyToken transfer failed");
        uint256 R1 = currencyToken.balanceOf(address(this));
        // Update the reserve ratio K
        reserveRatio = (R1 * reserveRatio) / R0;

        require(reserveRatio >= (PRECISION / 2) && reserveRatio <= PRECISION, "K being outside of range");//Check the range of K value after adding reserve
    }

    function distributeFees() external onlyOwner nonReentrant {
        require(poolStatus == PoolStatus.OPEN, "Pool not open");
        require(block.timestamp > (lastTimestamp + EPOCHDURATION), "Epoch duration not met");

        //Distribute the accumulated fees within each epoch.
        if(associatedBunusPoolAddr == address(0)){
            currencyToken.transfer(msg.sender, accumulatedFees);
            feeForContributorsLast = 0;
        }else {
            uint256 feeForContributors = accumulatedFees * bonusRatio / PRECISION;
            currencyToken.transfer(associatedBunusPoolAddr, feeForContributors);
            feeForContributorsLast = feeForContributors;
            uint256 feeForOwner = accumulatedFees - feeForContributors;
            currencyToken.transfer(msg.sender, feeForOwner);
        }
        
        accumulatedFees = 0;
        lastTimestamp = block.timestamp;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override { 
        super._beforeTokenTransfer(from, to, amount);
        require(poolStatus != PoolStatus.CLOSED, "Pool closed");
        require(isTransferEnabled || from == address(0) || to == address(0), "Transfer disabled"); 
    }

    function manageTransfer(bool _isTransferEnabled) external onlyOwner nonReentrant {
        isTransferEnabled = _isTransferEnabled;
    }

    function closePool() external onlyOwner nonReentrant {
        poolStatus= PoolStatus.CLOSED;
    }
}
