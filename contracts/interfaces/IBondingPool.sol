//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

interface IBondingPool {
    function feeForContributorsLast() external view returns (uint256);
    function lastTimestamp() external view returns(uint256);
}
