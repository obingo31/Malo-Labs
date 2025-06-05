// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "../../../src/Staking.sol";

abstract contract StakingTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               HANDLER-SPECIFIC POST CONDITIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // function assert_STAKE_HSPOST_A(
    //     uint256 amount
    // ) internal {
    //     eq(_after.balance_actor, _before.balance_actor + amount, STAKE_HSPOST_A);
    //     eq(_after.totalStaked, _before.totalStaked + amount, STAKE_HSPOST_A);
    // }

    // Add a constant error message for unstake postconditions
    // string constant STAKE_HSPOST_C = "Unstake postcondition failed";

    // HSPOST C: Validate unstake decreases balance and totalStaked
    function assert_STAKE_HSPOST_C(
        uint256 amount
    ) internal {
        eq(_after.balance_actor, _before.balance_actor - amount, STAKE_HSPOST_C);
        eq(_after.totalStaked, _before.totalStaked - amount, STAKE_HSPOST_C);
    }

    // Clamped stake handler
    function staking_stake_clamped(
        uint256 amount
    ) public asActor {
        // Clamp amount to non-zero and reasonable range
        amount = between(amount, 1, type(uint128).max);

        // Call unclamped handler
        staking_stake(amount);

        // Validate HSPOST: balance and totalStaked increase by amount
        assert_STAKE_HSPOST_A(amount);
    }

    // Clamped unstake handler
    function staking_unstake_clamped(
        uint256 amount
    ) public asActor {
        // Clamp amount to non-zero and within actor's unlocked balance
        amount = between(amount, 1, staking.unlockedBalanceOf(_getActor()));

        // Call unclamped handler
        staking_unstake(amount);

        // Validate HSPOST: balance and totalStaked decrease by amount
        assert_STAKE_HSPOST_C(amount);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function staking_allowManager(address _lockManager, uint256 _allowance, bytes memory _data) public asActor {
        staking.allowManager(_lockManager, _allowance, _data);
    }

    function staking_claimRewards() public asActor {
        staking.claimRewards();
    }

    function staking_decreaseLockAllowance(address _user, address _lockManager, uint256 _allowance) public asActor {
        staking.decreaseLockAllowance(_user, _lockManager, _allowance);
    }

    function staking_emergencyWithdraw() public asActor {
        staking.emergencyWithdraw();
    }

    function staking_grantRole(bytes32 role, address account) public asActor {
        staking.grantRole(role, account);
    }

    function staking_increaseLockAllowance(address _lockManager, uint256 _allowance) public asActor {
        staking.increaseLockAllowance(_lockManager, _allowance);
    }

    function staking_lock(address _user, uint256 _amount) public asActor {
        staking.lock(_user, _amount);
    }

    function staking_notifyRewardAmount(
        uint256 reward
    ) public asActor {
        staking.notifyRewardAmount(reward);
    }

    function staking_pause() public asAdmin {
        staking.pause();
    }

    function staking_renounceRole(bytes32 role, address callerConfirmation) public asActor {
        staking.renounceRole(role, callerConfirmation);
    }

    function staking_revokeRole(bytes32 role, address account) public asActor {
        staking.revokeRole(role, account);
    }

    function staking_setFeeRecipient(
        address newRecipient
    ) public asActor {
        staking.setFeeRecipient(newRecipient);
    }

    function staking_setProtocolFee(
        uint256 newFee
    ) public asAdmin {
        staking.setProtocolFee(newFee);
    }

    function staking_setRewardPeriod(
        uint256 newPeriod
    ) public asActor {
        staking.setRewardPeriod(newPeriod);
    }

    function staking_setRewardRate(
        uint256 _rewardRate
    ) public asActor {
        staking.setRewardRate(_rewardRate);
    }

    function staking_setRewardsDistribution(
        address _rewardsDistribution
    ) public asActor {
        staking.setRewardsDistribution(_rewardsDistribution);
    }

    function staking_slash(address _from, address _to, uint256 _amount) public asAdmin {
        staking.slash(_from, _to, _amount);
    }

    function staking_slashAndUnstake(address _from, address _to, uint256 _amount) public asAdmin {
        staking.slashAndUnstake(_from, _to, _amount);
    }

    function staking_stake(
        uint256 amount
    ) public asActor {
        staking.stake(amount);
    }

    function staking_stakeFor(address _user, uint256 _amount) public asActor {
        staking.stakeFor(_user, _amount);
    }

    function staking_transfer(address _to, uint256 _amount) public asActor {
        staking.transfer(_to, _amount);
    }

    function staking_transferAndUnstake(address _to, uint256 _amount) public asActor {
        staking.transferAndUnstake(_to, _amount);
    }

    function staking_unlock(address _user, address _lockManager, uint256 _amount) public asActor {
        staking.unlock(_user, _lockManager, _amount);
    }

    function staking_unlockAndRemoveManager(address _user, address _lockManager) public asAdmin {
        staking.unlockAndRemoveManager(_user, _lockManager);
    }

    function staking_unpause() public asAdmin {
        staking.unpause();
    }

    function staking_unstake(
        uint256 _amount
    ) public asActor {
        staking.unstake(_amount);
    }
}
