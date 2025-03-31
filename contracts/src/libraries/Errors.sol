// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Errors
library Errors {
    // Basic errors
    error ZeroAddress();
    error ZeroAmount();
    error NULL_ADDRESS();
    error NULL_AMOUNT();
    error SameTokenAddresses();

    // Balance and allowance errors
    error InsufficientBalance();
    error INSUFFICIENT_BALANCE();
    error InsufficientAllowance();
    error WithdrawAmountExceedsBalance();
    error WITHDRAW_AMOUNT_EXCEEDS_BALANCE();

    // Transfer errors
    error TRANSFER_FAILED();

    // Contract state errors
    error ContractPaused();
    error CONTRACT_PAUSED();
    error ContractNotPaused();
    error STAKING_PAUSED();
    error NOT_PAUSED();
    error ALREADY_PAUSED();

    // Reward system errors
    error ClaimLockActive();
    error MaxDailyClaimExceeded();
    error NoStakedBalance();
    error NoRewardsAvailable();
    error NO_REWARDS_AVAILABLE();
    error EmergencyLockActive();
    error InsufficientRewardTokens();
    error ActiveRewardsPeriod();
    error ACTIVE_REWARDS_PERIOD();
    error REWARDS_PERIOD_NOT_ENDED();
    error PreviousPeriodActive();

    // Configuration errors
    error InvalidProtocolFee();
    error INVALID_FEE_AMOUNT();
    error InvalidRewardPeriod();
    error INVALID_REWARD_PERIOD();
    error RewardRateTooHigh();
    error INVALID_REWARD_RATE();
    error INVALID_TOKEN();
    error InvalidAddress();
    error ActorExists();

    // Authentication errors
    error CallerNotRewardsDistributor();

    // DOS error
    error DOS();

    // Access control errors
    error AccessControlUnauthorizedAccount();
    error UnauthorizedAccess();
    error NotAuthorized();

    // Locks
    error LockAlreadyExists();
    error LockNotFound();
    error LockNotActive();
    error LockNotExpired();
    error LockExpired();
    error LockNotActiveOrExpired();
    error LockActive();
    error LockDoesNotExist();
    error CannotUnlock();
    error LockedTokensExist();
    error LockedTokens();

    // Allowance errors
    error AllowanceNotZero();
    error AllowanceNotMax();
    error AllowanceNotMaxOrZero();
    error AllowanceCannotBeZero();
    error InsufficientLock();
}
