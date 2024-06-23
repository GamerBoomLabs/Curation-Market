//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ContributionPool.sol";
import "./interfaces/IContributionFactory.sol";

contract ContributionFactory is IContributionFactory, Ownable, ReentrancyGuard {
    address[] public pools;

    function createContributionPool(
        string calldata _name,
        string calldata _symbol,
        address _currencyToken,
        address _associatedBondingPoolAddr,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _hardcap,
        bytes32 _root // The root of the whitelist Merkle Tree
    ) external onlyOwner nonReentrant {
        bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, _currencyToken));
        ContributionPool newContributionPool = new ContributionPool{salt: _salt}();

        //Initialize the newly created contribution contract
        ContributionPool(newContributionPool).initialize(IERC20(_currencyToken), _associatedBondingPoolAddr, _minContribution, _maxContribution, _hardcap, _root);

        // Transfer ownership of the ContributionPool to the owner of the factory
        ContributionPool(newContributionPool).transferOwnership(owner());

        pools.push(address(newContributionPool));
    }

    function allPairsLength() external view returns (uint256) {
        return pools.length;
    }
}
