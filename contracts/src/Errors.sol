// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface Errors {
    error ZeroAddress();
    error ZeroAmount();
    error SameTokenAddresses();
    error InsufficientBalance();
    error InsufficientAllowance();
    error ContractPaused();
    error ClaimLockActive();
    error MaxDailyClaimExceeded();
    error NoStakedBalance();
    error ContractNotPaused();
    error EmergencyLockActive();
    error InsufficientRewardTokens();
    error ActiveRewardsPeriod();
    error InvalidProtocolFee();
    error InvalidRewardPeriod();
    error RewardRateTooHigh();
    error WithdrawAmountExceedsBalance();
    error PreviousPeriodActive();
    error NoRewardsAvailable();
}