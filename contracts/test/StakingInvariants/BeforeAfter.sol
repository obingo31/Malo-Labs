// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Setup} from "./Setup.sol";
import {Strings, Pretty} from "./Pretty.sol";

import {StakingPostconditions} from "./StakingPostconditions.sol";
import {StakingInvariants} from "./StakingInvariants.sol";

abstract contract BeforeAfter is Setup, StakingPostconditions, StakingInvariants {
    using Strings for string;
    using Pretty for uint256;
    using Pretty for bool;

    struct Vars {
        uint256 balance_actor;
        uint256 earned_actor;
        uint256 unlockedBalance_actor;
        uint256 totalStaked;
        uint256 totalRewardsDistributed;
        uint256 protocolFee;
        uint256 rewardRate;
        uint256 rewardPeriod;
        uint256 rewardPerTokenStored;
        address feeRecipient;
        bool paused;
    }

    Vars internal _before;
    Vars internal _after;

    modifier updateGhosts() {
        __before();
        _;
        __after();
    }

    function __before() internal {
        address actor = _getActor();
        _before = Vars({
            balance_actor: staking.balanceOf(actor),
            earned_actor: staking.earned(actor),
            unlockedBalance_actor: staking.unlockedBalanceOf(actor),
            totalStaked: staking.totalStaked(),
            totalRewardsDistributed: staking.totalRewardsDistributed(),
            protocolFee: staking.protocolFee(),
            rewardRate: staking.rewardRate(),
            rewardPeriod: staking.rewardPeriod(),
            rewardPerTokenStored: staking.rewardPerTokenStored(),
            feeRecipient: staking.feeRecipient(),
            paused: staking.paused()
        });
    }

    function __after() internal {
        address actor = _getActor();
        _after = Vars({
            balance_actor: staking.balanceOf(actor),
            earned_actor: staking.earned(actor),
            unlockedBalance_actor: staking.unlockedBalanceOf(actor),
            totalStaked: staking.totalStaked(),
            totalRewardsDistributed: staking.totalRewardsDistributed(),
            protocolFee: staking.protocolFee(),
            rewardRate: staking.rewardRate(),
            rewardPeriod: staking.rewardPeriod(),
            rewardPerTokenStored: staking.rewardPerTokenStored(),
            feeRecipient: staking.feeRecipient(),
            paused: staking.paused()
        });
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   GLOBAL POST CONDITIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Helper function to check if rewards were updated
    function _isRewardUpdated() internal view returns (bool) {
        return _before.rewardPerTokenStored != _after.rewardPerTokenStored;
    }

    // GPOST A: Reward updates only during specific operations
    function assert_STAKING_GPOST_A() internal view {
        if (_isRewardUpdated()) {
            bytes4 sig = msg.sig;
            bool validOperation = sig == staking.stake.selector ||
                sig == staking.unstake.selector ||
                sig == staking.claimRewards.selector ||
                sig == staking.notifyRewardAmount.selector;
            require(validOperation, CORE_GPOST_A);
        }
    }

    // GPOST B & C: Ensure totalStaked and totalRewardsDistributed don't decrease unexpectedly
    function assert_STAKING_GPOST_BC() internal view {
        if (_isRewardUpdated()) {
            // GPOST B: totalStaked should not decrease
            require(_after.totalStaked >= _before.totalStaked, CORE_GPOST_B);
            // GPOST C: totalRewardsDistributed should not decrease
            require(_after.totalRewardsDistributed >= _before.totalRewardsDistributed, CORE_GPOST_C);
        }
    }

    // GPOST D: Restrict unstake operations based on state
    function assert_STAKING_GPOST_D() internal view {
        if (msg.sig == staking.unstake.selector) {
            // Cannot unstake if paused
            require(!_after.paused, CORE_GPOST_E);
            // Cannot unstake if all funds are locked
            require(_before.unlockedBalance_actor > 0, CORE_GPOST_E);
        }
    }

    // GPOST E: Ensure no invalid state transitions
    function assert_STAKING_GPOST_E() internal view {
        // Ensure totalStaked doesn't change unexpectedly
        if (msg.sig != staking.stake.selector && msg.sig != staking.unstake.selector) {
            require(_after.totalStaked == _before.totalStaked, CORE_GPOST_E);
        }
    }

    // Validate all global postconditions
    function _validateStateConsistency() internal view {
        assert_STAKING_GPOST_A();
        assert_STAKING_GPOST_BC();
        assert_STAKING_GPOST_D();
        assert_STAKING_GPOST_E();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               HANDLER-SPECIFIC POST CONDITIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // HSPOST A: Validate stake increases balance and totalStaked
    // function assert_STAKE_HSPOST_A(
    //     uint256 amount
    // ) internal view {
    //     eq(_after.balance_actor, _before.balance_actor + amount, STAKE_HSPOST_A);
    //     eq(_after.totalStaked, _before.totalStaked + amount, STAKE_HSPOST_A);
    // }
}
