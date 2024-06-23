//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBonusFactory {
    function createContributionBonus(
        string memory _name,
        string memory _symbol,
        address _currencyToken,
        address _associatedBondingPool,
        address _associatedContributionPool
    ) external;

    function pools(uint256) external view returns (address);
    function allPairsLength() external view returns (uint256);
}
