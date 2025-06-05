// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Setup} from "./Setup.sol";
import {Strings, Pretty} from "./Pretty.sol";

// import {StakingPostconditions} from "./StakingPostconditions.sol";
// import {StakingInvariants} from "./StakingInvariants.sol";
import {Merged} from "./Merged.sol";

abstract contract BeforeAfter is Setup, Merged, Test {
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

    function assert_STAKING_GPOST_A() internal {
        if (_isRewardUpdated()) {
            assertTrue(
                msg.sig == staking.stake.selector || msg.sig == staking.unstake.selector
                    || msg.sig == staking.claimRewards.selector || msg.sig == staking.notifyRewardAmount.selector,
                CORE_GPOST_A
            );
        }
    }

    function assert_STAKING_GPOST_BC() internal {
        if (_isRewardUpdated()) {
            assertTrue(_after.totalStaked >= _before.totalStaked, CORE_GPOST_B);
            assertTrue(_after.totalRewardsDistributed >= _before.totalRewardsDistributed, CORE_GPOST_C);
        }
    }

    function assert_STAKING_GPOST_D() internal {
        if (msg.sig == staking.unstake.selector) {
            assertTrue(!_after.paused, CORE_GPOST_D1);
            assertTrue(_before.unlockedBalance_actor > 0, CORE_GPOST_D2);
        }
    }

    function assert_STAKING_GPOST_E() internal {
        if (msg.sig != staking.stake.selector && msg.sig != staking.unstake.selector) {
            assertTrue(_after.totalStaked == _before.totalStaked, CORE_GPOST_E);
        }
    }

    // Validate all global postconditions
    function _validateStateConsistency() internal {
        assert_STAKING_GPOST_A();
        assert_STAKING_GPOST_BC();
        assert_STAKING_GPOST_D();
        assert_STAKING_GPOST_E();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               HANDLER-SPECIFIC POST CONDITIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    string constant STAKE_HSPOST =
        "STAKE_HSPOST_A: After staking, actor's balance and total staked should increase by the staked amount";

    function assert_STAKE_HSPOST_A(
        uint256 amount
    ) internal {
        assertTrue(_after.balance_actor == _before.balance_actor + amount, STAKE_HSPOST);
        assertTrue(_after.totalStaked == _before.totalStaked + amount, STAKE_HSPOST);
    }
}

string constant CORE_GPOST_A = "CORE_GPOST_A";
string constant CORE_GPOST_B = "CORE_GPOST_B";
string constant CORE_GPOST_C = "CORE_GPOST_C";
string constant CORE_GPOST_D = "CORE_GPOST_D";
string constant CORE_GPOST_E = "CORE_GPOST_E";
string constant CORE_GPOST_D1 = "CORE_GPOST_D1: unstake should not be paused";
string constant CORE_GPOST_D2 = "CORE_GPOST_D2: actor must have unlocked balance to unstake";
