//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @title StakingInvariants
/// @notice Invariants specification for staking protocol
abstract contract StakingInvariants {
    //////////////////////////////////////////////////////////////////////////////////////////////
    //                                      CORE INVARIANTS                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Fundamental properties that must always hold true
    string constant CORE_INV_A = "CORE_INV_A: totalStaked == sum(balanceOf(users))";
    string constant CORE_INV_B = "CORE_INV_B: balanceOf(user) == lockedBalanceOf(user) + unlockedBalanceOf(user)";
    string constant CORE_INV_C = "CORE_INV_C: protocolFee <= MAX_FEE";
    string constant CORE_INV_D = "CORE_INV_D: feeRecipient != address(0)";
    string constant CORE_INV_E = "CORE_INV_E: stakingToken.balanceOf(address(staking)) >= totalStaked";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      REWARD SYSTEM                                       //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant REWARD_INV_A = "REWARD_INV_A: totalRewardsDistributed <= rewardToken.balanceOf(address(staking))";
    string constant REWARD_INV_B = "REWARD_INV_B: periodFinish > block.timestamp => rewardRate > 0";
    string constant REWARD_INV_C = "REWARD_INV_C: rewardRate * rewardPeriod <= rewardToken.balanceOf(address(staking))";
    string constant REWARD_INV_D = "REWARD_INV_D: earned(user) <= maxPossibleRewards(user)";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      LOCKING MECHANISMS                                 //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant LOCK_INV_A = "LOCK_INV_A: sum(lockedBalanceOf(users)) <= totalStaked";
    string constant LOCK_INV_B =
        "LOCK_INV_B: lockManagerAllowance(user, manager) >= lockedBalanceByManager(user, manager)";
    string constant LOCK_INV_C = "LOCK_INV_C: slash operations preserve totalStaked";
    string constant LOCK_INV_D = "LOCK_INV_D: unlock operations reduce lockedBalanceOf(user)";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      ACCESS CONTROL                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant ACCESS_INV_A = "ACCESS_INV_A: Only PAUSER_ROLE can call pause() or unpause()";
    string constant ACCESS_INV_B = "ACCESS_INV_B: Critical parameters modified only by DEFAULT_ADMIN_ROLE";
    string constant ACCESS_INV_C = "ACCESS_INV_C: Lock managers cannot lock beyond approved allowance";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      STATE TRANSITIONS                                  //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant STATE_INV_A =
        "STATE_INV_A: paused == true => state-changing operations revert except emergencyWithdraw";
    string constant STATE_INV_B = "STATE_INV_B: emergencyWithdraw sets balanceOf(user) to zero";
    string constant STATE_INV_C = "STATE_INV_C: stake and unstake operations preserve stakingToken supply";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      FEE MANAGEMENT                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant FEE_INV_A = "FEE_INV_A: feeTransfers == (rewardsClaimed * protocolFee) / 1000";
    string constant FEE_INV_B = "FEE_INV_B: feeRecipient rewardToken balance increases on reward claims";
    string constant FEE_INV_C = "FEE_INV_C: protocolFee changes emit ProtocolFeeUpdated event";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      TIME-BASED INVARIANTS                              //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant TIME_INV_A = "TIME_INV_A: lastUpdateTime <= block.timestamp";
    string constant TIME_INV_B = "TIME_INV_B: periodFinish >= lastUpdateTime";
    string constant TIME_INV_C = "TIME_INV_C: rewardPerTokenStored increases monotonically when rewardRate > 0";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      TOKEN INTEGRITY                                    //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant TOKEN_INV_A = "TOKEN_INV_A: stakingToken.totalSupply() >= totalStaked";
    string constant TOKEN_INV_B = "TOKEN_INV_B: rewardToken.totalSupply() >= totalRewardsDistributed";
    string constant TOKEN_INV_C = "TOKEN_INV_C: transfer operations preserve totalStaked";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      EMERGENCY PROTOCOLS                                //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant EMERG_INV_A = "EMERG_INV_A: emergencyWithdraw only callable when paused";
    string constant EMERG_INV_B = "EMERG_INV_B: emergencyWithdraw resets earned(user) to zero";
    string constant EMERG_INV_C = "EMERG_INV_C: pause and unpause emit Paused and Unpaused events";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      DELEGATION CONTROL                                //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant DELEGATE_INV_A = "DELEGATE_INV_A: stakeFor preserves totalStaked";
    string constant DELEGATE_INV_B = "DELEGATE_INV_B: transferAndUnstake reverts if amount exceeds unlockedBalanceOf";
    string constant DELEGATE_INV_C = "DELEGATE_INV_C: slash preserves totalStaked and totalRewardsDistributed";
    string constant DELEGATE_INV_D = "DELEGATE_INV_D: transferAndUnstake reverts if amount exceeds lockedBalanceOf";
    string constant DELEGATE_INV_E = "DELEGATE_INV_E: transferAndUnstake reduces unlockedBalanceOf by amount";

    // Storage for invariants - using function pointer type
    function() internal[] internal _invariants;

    // Function to add invariant
    function _addInvariant(
        function() internal inv
    ) internal {
        _invariants.push(inv);
    }

    /// === Core Invariant Functions === ///
    function invariant_CORE_INV_A() internal virtual {
        require(true, CORE_INV_A);
    }

    function invariant_CORE_INV_B() internal virtual {
        require(true, CORE_INV_B);
    }

    function invariant_CORE_INV_C() internal virtual {
        require(true, CORE_INV_C);
    }

    function invariant_CORE_INV_D() internal virtual {
        require(true, CORE_INV_D);
    }

    function invariant_CORE_INV_E() internal virtual {
        require(true, CORE_INV_E);
    }

    /// === Reward System Invariant Functions === ///
    function invariant_REWARD_INV_A() internal virtual {
        require(true, REWARD_INV_A);
    }

    function invariant_REWARD_INV_B() internal virtual {
        require(true, REWARD_INV_B);
    }

    function invariant_REWARD_INV_C() internal virtual {
        require(true, REWARD_INV_C);
    }

    function invariant_REWARD_INV_D() internal virtual {
        require(true, REWARD_INV_D);
    }

    /// === Lock Mechanism Invariant Functions === ///
    function invariant_LOCK_INV_A() internal virtual {
        require(true, LOCK_INV_A);
    }

    // Function to check all invariants
    function checkInvariants() internal virtual {
        for (uint256 i = 0; i < _invariants.length; i++) {
            _invariants[i]();
        }
    }
}
