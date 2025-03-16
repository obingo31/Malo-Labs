// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Errors.sol";

abstract contract RewardsDistributionRecipient is AccessControl, Errors {
    bytes32 public constant REWARDS_DISTRIBUTOR_ROLE = 
        keccak256("REWARDS_DISTRIBUTOR_ROLE");
    
    IERC20 public immutable maloToken;

    constructor(address initialOwner, address _maloToken) {
        if (initialOwner == address(0)) revert ZeroAddress();
        if (_maloToken == address(0)) revert ZeroAddress();
        
        maloToken = IERC20(_maloToken);
        
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(REWARDS_DISTRIBUTOR_ROLE, initialOwner);
    }

    modifier onlyRewardsDistribution() {
        if (!hasRole(REWARDS_DISTRIBUTOR_ROLE, msg.sender)) {
            revert CallerNotRewardsDistributor();
        }
        _;
    }

    function fundRewardPool(uint256 amount) external onlyRewardsDistribution {
        if (amount == 0) revert ZeroAmount();
        
        maloToken.transferFrom(msg.sender, address(this), amount);
    }
}