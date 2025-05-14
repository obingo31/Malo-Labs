// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title StakingInvariants
/// @notice Invariants specification for staking protocol
abstract contract StakingInvariants {
    //////////////////////////////////////////////////////////////////////////////////////////////
    //                                      CORE INVARIANTS                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Fundamental properties that must always hold true
    string constant CORE_INV_A = "CORE_INV_A: totalStaked == sum(balanceOf)";
    string constant CORE_INV_B = "CORE_INV_B: balanceOf(user) == lockedOf(user) + unlockedOf(user)";
    string constant CORE_INV_C = "CORE_INV_C: protocolFee <= MAX_FEE";
    string constant CORE_INV_D = "CORE_INV_D: feeRecipient != address(0)";
    string constant CORE_INV_E = "CORE_INV_E: stakingToken.balanceOf(address(this)) >= totalStaked";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      REWARD SYSTEM                                       //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant REWARD_INV_A = "REWARD_INV_A: totalRewardsDistributed <= rewardToken.balanceOf(address(this))";
    string constant REWARD_INV_B = "REWARD_INV_B: periodFinish > block.timestamp => rewardRate > 0";
    string constant REWARD_INV_C = "REWARD_INV_C: rewardRate * rewardPeriod <= rewardToken.balance";
    string constant REWARD_INV_D = "REWARD_INV_D: earned(user) <= maxRewardsForDuration(user)";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      LOCKING MECHANISMS                                 //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant LOCK_INV_A = "LOCK_INV_A: sum(lockedOf) <= totalStaked";
    string constant LOCK_INV_B = "LOCK_INV_B: lockManagerAllowance(user,manager) >= lockedByManager(user,manager)";
    string constant LOCK_INV_C = "LOCK_INV_C: slash operations preserve totalStaked";
    string constant LOCK_INV_D = "LOCK_INV_D: unlock operations decrease locked balance";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      ACCESS CONTROL                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant ACCESS_INV_A = "ACCESS_INV_A: Only PAUSER_ROLE can toggle pause state";
    string constant ACCESS_INV_B = "ACCESS_INV_B: Critical params changed only by authorized roles";
    string constant ACCESS_INV_C = "ACCESS_INV_C: Lock managers cannot exceed approved allowances";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      STATE TRANSITIONS                                  //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant STATE_INV_A = "STATE_INV_A: paused == true => all state-changing functions revert";
    string constant STATE_INV_B = "STATE_INV_B: emergencyWithdraw resets user balance to zero";
    string constant STATE_INV_C = "STATE_INV_C: stake/unstake operations preserve token supply";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      FEE MANAGEMENT                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant FEE_INV_A = "FEE_INV_A: feeTransfers == (rewardsClaimed * protocolFee) / 1000";
    string constant FEE_INV_B = "FEE_INV_B: feeRecipient balance increases on claims";
    string constant FEE_INV_C = "FEE_INV_C: fee changes emit ProtocolFeeUpdated event";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      TIME-BASED INVARIANTS                              //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant TIME_INV_A = "TIME_INV_A: lastUpdateTime <= block.timestamp";
    string constant TIME_INV_B = "TIME_INV_B: periodFinish >= lastUpdateTime";
    string constant TIME_INV_C = "TIME_INV_C: rewardPerToken increases monotonically when active";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      TOKEN INTEGRITY                                    //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant TOKEN_INV_A = "TOKEN_INV_A: stakingToken.totalSupply() >= totalStaked";
    string constant TOKEN_INV_B = "TOKEN_INV_B: rewardToken.totalSupply() >= totalRewardsDistributed";
    string constant TOKEN_INV_C = "TOKEN_INV_C: transferFrom operations preserve totalStaked";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      EMERGENCY PROTOCOLS                                //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant EMERG_INV_A = "EMERG_INV_A: emergencyWithdraw available only when paused";
    string constant EMERG_INV_B = "EMERG_INV_B: emergencyWithdraw forfeits unclaimed rewards";
    string constant EMERG_INV_C = "EMERG_INV_C: pause/unpause emits Paused/Unpaused events";

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      DELEGATION CONTROL                                //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    string constant DELEGATE_INV_A = "DELEGATE_INV_A: stakeFor preserves totalStaked invariant";
    string constant DELEGATE_INV_B = "DELEGATE_INV_B: transferAndUnstake respects locking";
    string constant DELEGATE_INV_C = "DELEGATE_INV_C: slash preserves system totals";
    string constant DELEGATE_INV_D = "DELEGATE_INV_D: transferAndUnstake respects locking";
    string constant DELEGATE_INV_E = "DELEGATE_INV_E: transferAndUnstake respects unlocked balance";
}
