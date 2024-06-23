//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IContributionPool.sol";
import "./BonusPool.sol";

contract BonusFactory is  Ownable, ReentrancyGuard {
    address[] public pools;

    function createContributionBonus(
        string memory _name,
        string memory _symbol,
        address _currencyToken,
        address _associatedBondingPool,
        address _associatedContributionPool
    ) external onlyOwner nonReentrant {
        require(IContributionPool(_associatedContributionPool).getPoolStatus() == 2, "Associated contribution pool not completed");

        // Create the bonus contract for contributors
        bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, _currencyToken));
        BonusPool newBonusPool = new BonusPool{ salt: _salt}();

        newBonusPool.initialize(_currencyToken, _associatedBondingPool, _associatedContributionPool); 

        BonusPool(newBonusPool).transferOwnership(owner());

        pools.push(address(newBonusPool));
    }

    function allPairsLength() external view returns (uint256) {
        return pools.length;
    }
}
