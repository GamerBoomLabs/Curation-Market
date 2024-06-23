//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBondingCurveCalculator {

    function addToWhitelist(address _contract) external;
    function isWhitelisted(address _contract) external view returns (bool); 
    //Calculate the share amount of bonding pool for minting
    function calculateShareMinted(uint256 S0, uint256 currencyAmount, uint256 R0, uint256 reserveRatio, uint256 PRECISION) external returns (uint256);

    //Calculate the reserve token amount redeemed from bonding pool 
    function calculateReserveRedeemed(uint256 S0, uint256 blpAmount, uint256 R0, uint256 reserveRatio, uint256 PRECISION) external returns (uint256);

}
