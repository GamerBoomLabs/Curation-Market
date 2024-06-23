//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBondingFactory {
    function createBondingPool(
        bool _isContributionFunded,
        string memory _name,
        string memory _symbol,
        uint256 _initialReserveRatio,// The reserve ratio is scaled up by 10,000 to reduce precision loss.
        uint256 _initialReserve,
        uint256 _initialBlpMint,
        address _feeCollector, 
        address _currencyToken     
    ) external;

    function pools(uint256) external view returns (address);
    function allPairsLength () external view returns (uint256);
}
