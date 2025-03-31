// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

abstract contract PropertiesSpecifications {
    // Staking balances
    string internal constant STAKED_01 = "STAKED_01: Total staked must match sum of individual balances";
    string internal constant STAKED_02 = "STAKED_02: Individual balances must never be negative";

    // Emergency operations
    string internal constant EMERGENCY_05 = "EMERGENCY_05: Emergency withdraw must return locked tokens";

    // Reward accounting
    string internal constant REWARD_01 = "REWARD_01: Total distributed rewards must equal claimed + fees + pending";
    string internal constant REWARD_02 = "REWARD_02: Token supply must match contract balance + distributed amounts";
    string internal constant REWARD_03 = "REWARD_03: Reward calculation must match time-based accrual";

    // Fee handling
    string internal constant FEE_01 = "FEE_01: Protocol fee must never exceed maximum allowed";
    string internal constant FEE_02 = "FEE_02: Fee recipient balance must match calculated fees";

    // Reward period
    string internal constant PERIOD_01 = "PERIOD_01: Contract balance must sustain reward rate for period";
    string internal constant PERIOD_02 = "PERIOD_02: Reward changes must only apply to future periods";

    // Emergency operations
    string internal constant EMERGENCY_01 = "EMERGENCY_01: Withdraw must reset user balance";
    string internal constant EMERGENCY_02 = "EMERGENCY_02: Withdraw must clear pending rewards";
    string internal constant EMERGENCY_03 = "EMERGENCY_03: Withdraw must preserve historical claims";
    string internal constant EMERGENCY_04 = "EMERGENCY_04: Emergency withdraw requires paused state";

    // Access control
    string internal constant ACCESS_01 = "ACCESS_01: Fee changes require FEE_SETTER_ROLE";
    string internal constant ACCESS_02 = "ACCESS_02: Period changes require DEFAULT_ADMIN_ROLE";
    string internal constant ACCESS_03 = "ACCESS_03: Fee recipient changes require DEFAULT_ADMIN_ROLE";
    string internal constant ACCESS_04 = "ACCESS_04: Updated fee must not exceed maximum";

    // Pause state
    string internal constant PAUSED_01 = "PAUSED_01: No staking/unstaking allowed when paused";
    string internal constant PAUSED_02 = "PAUSED_02: Only PAUSER_ROLE can toggle pause state";

    // Time integrity
    string internal constant TIME_01 = "TIME_01: Reward distribution resistant to time manipulation";

    // General security
    string internal constant REENTRANCY_01 = "REENTRANCY_01: Contract must prevent reentrant calls";
    string internal constant SANITY_01 = "SANITY_01: Protocol initialization parameters must be valid";

    // Token operations
    string internal constant TRANSFER_01 = "TRANSFER_01: Token transfers must maintain total supply";
    string internal constant APPROVAL_01 = "APPROVAL_01: Token approvals must not overflow";

    // Configuration
    string internal constant CONFIG_01 = "CONFIG_01: Reward rate must be sustainable with current balance";
    string internal constant CONFIG_02 = "CONFIG_02: Minimum stake duration must be positive";

    // Denial-of-Service protections
    string internal constant DOS = "DOS: Denial of Service";
    string internal constant DOS_01 = "DOS_01: Valid operations must not revert when preconditions met";
    string internal constant DOS_02 = "DOS_02: Gas usage must remain below block gas limit";
    string internal constant DOS_03 = "DOS_03: Array operations must handle maximum practical sizes";
}
