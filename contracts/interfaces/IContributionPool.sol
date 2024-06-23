//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

interface IContributionPool {
    function contributions(address) external view returns (uint256);
    function totalContribution() external view returns (uint256);
    function getPoolStatus() external view returns (uint8);
    function contributionKeys(uint256) external view returns (address);
    function getContributionKeysLength() external view returns (uint256);
}
