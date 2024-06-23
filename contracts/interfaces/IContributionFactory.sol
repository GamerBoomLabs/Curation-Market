//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IContributionFactory {
    function createContributionPool(
        string calldata _name,
        string calldata _symbol,
        address _currencyToken,
        address _associatedBondingPoolAddr,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _hardcap,
        bytes32 _root // The root of the whitelist Merkle Tree
    ) external;

    function pools(uint256) external view returns (address);
    function allPairsLength() external view returns (uint256);
}
