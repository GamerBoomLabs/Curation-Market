//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBondingCurveCalculator.sol";
import "./interfaces/IBondingFactory.sol";
import "./BondingPool.sol";

contract BondingFactory is IBondingFactory, Ownable, ReentrancyGuard {
    address[] public pools;
    IBondingCurveCalculator private bondingCurveCalculator;

    constructor (IBondingCurveCalculator _bondingCurveCalculator) {
        bondingCurveCalculator = _bondingCurveCalculator;
    }

    function createBondingPool(
        bool _isContributionNeeded,
        string memory _name,
        string memory _symbol,
        uint256 _initialReserveRatio,// The reserve ratio is scaled up by 10,000 to reduce precision loss.
        uint256 _initialReserve,
        uint256 _initialBlpMint,
        address _feeCollector, 
        address _currencyToken     
    ) external onlyOwner nonReentrant {
        // Deploy and initialize the new BondingPool contract
        bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, _currencyToken));
        BondingPool newBondingPool = new BondingPool{ salt: _salt}( _name, _symbol);
        bondingCurveCalculator.addToWhitelist(address(newBondingPool));

        //Transfer the initial reserve to the newly created pool
        if(!_isContributionNeeded) {
            require(IERC20(_currencyToken).balanceOf(address(msg.sender)) >= _initialReserve, "Inssuficient balance in sender's account");
            IERC20(_currencyToken).transferFrom(msg.sender, address(newBondingPool), _initialReserve); 
            require(IERC20(_currencyToken).balanceOf(address(newBondingPool)) >= _initialReserve, "Insufficient initial reserve");          
        } 

        newBondingPool.initialize(_isContributionNeeded, _feeCollector, IERC20(_currencyToken), bondingCurveCalculator, _initialReserveRatio, _initialReserve, _initialBlpMint);
        
        pools.push(address(newBondingPool));
    }

    function allPairsLength() external view returns (uint256) {
        return pools.length;
    }
}
