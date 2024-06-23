//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "prb-math/contracts/PRBMathUD60x18.sol";
import "./interfaces/IBondingCurveCalculator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BondingCurveCalculator is Ownable, ReentrancyGuard {
    mapping(address => bool) private whitelist;
    address private bondingFactory;

    modifier onlyFactory {
        require(msg.sender == bondingFactory, "Unauthorized access");
        _;
    }

    //Modifier to restrict access only to contracts in the whitelist
    modifier onlyWhitelisted {
        require(whitelist[msg.sender], "Unauthorized access");
        _;
    }

    function setFactoryContract(address _bondingFactory) external onlyOwner {
        bondingFactory = _bondingFactory;
    }

    function addToWhitelist(address _contract) external onlyFactory {
        whitelist[_contract] = true;
    }

    function removeFromWhitelist(address _contract) external onlyOwner {
        whitelist[_contract] = false;
    }

    function isWhitelisted(address _contract) external view returns (bool) {
        return whitelist[_contract];
    }

    //Calculate the share amount of bonding pool for minting
    function calculateShareMinted(uint256 S0, uint256 currencyAmount, uint256 R0, uint256 reserveRatio, uint256 PRECISION) external  onlyWhitelisted nonReentrant returns (uint256) {
        uint256 ratio = PRBMathUD60x18.div(currencyAmount, R0);
        uint256 onePlusRatio = PRBMathUD60x18.fromUint(1) + ratio;
        uint256 powerArgument = PRBMathUD60x18.div(reserveRatio, PRECISION);
        uint256 powered = PRBMathUD60x18.pow(onePlusRatio, powerArgument);
        uint256 blpAmount = PRBMathUD60x18.mul(S0, (powered - PRBMathUD60x18.fromUint(1)));
        return blpAmount;
    }

    //Calculate the reserve token amount redeemed from bonding pool 
    function calculateReserveRedeemed(uint256 S0, uint256 blpAmount, uint256 R0, uint256 reserveRatio, uint256 PRECISION) external onlyWhitelisted nonReentrant returns (uint256) {
        uint256 ratio = PRBMathUD60x18.div(blpAmount, S0);
        uint256 onePlusRatio = PRBMathUD60x18.fromUint(1) + ratio;
        uint256 powerArgument = PRBMathUD60x18.div(PRECISION, reserveRatio);
        uint256 powered = PRBMathUD60x18.pow(onePlusRatio, powerArgument);
        uint256 currencyAmount = PRBMathUD60x18.mul(R0, (powered - PRBMathUD60x18.fromUint(1)));
        return currencyAmount;
    }
}
