// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Asserts} from "@chimera/Asserts.sol";
import {Staking} from "src/Staking.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Ghosts is Asserts {
    struct StakingVars {
        uint256 totalStaked;
        uint256 totalRewards;
        uint256 protocolFees;
        uint256 lastUpdateTime;
        uint256 periodFinish;
        mapping(address => uint256) userStakes;
        mapping(address => uint256) userRewards;
    }

    StakingVars internal _before;
    StakingVars internal _after;

    Staking public staking;
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    constructor(Staking _staking, IERC20 _stakingToken, IERC20 _rewardToken) {
        staking = _staking;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        _snapshot(_before);
    }

    modifier trackState() {
        _snapshot(_before);
        _;
        _snapshot(_after);
        _;
    }

    function _snapshot(StakingVars storage vars) internal {
        vars.totalStaked = staking.totalStaked();
        vars.totalRewards = rewardToken.balanceOf(address(staking));
        vars.protocolFees = 0; // Track separately
        vars.lastUpdateTime = staking.lastUpdateTime();
        vars.periodFinish = staking.periodFinish();
    }

    function _updateUserState(address user) internal {
        _before.userStakes[user] = staking.balanceOf(user);
        _before.userRewards[user] = staking.earned(user);
    }

    // Ghost state transitions
    function _ghostStake(address user, uint256 amount) internal {
        _after.totalStaked += amount;
        _after.userStakes[user] += amount;
    }

    function _ghostWithdraw(address user, uint256 amount) internal {
        _after.totalStaked -= amount;
        _after.userStakes[user] -= amount;
    }

    function _ghostClaim(address user) internal {
        uint256 reward = _after.userRewards[user];
        uint256 fee = (reward * staking.protocolFee()) / 1000;

        _after.totalRewards -= (reward - fee);
        _after.protocolFees += fee;
        _after.userRewards[user] = 0;
    }

    // Utility for tests
    function _getActors() internal view virtual returns (address[] memory);
}
