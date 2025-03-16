// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Protocol Constants
 * @notice Central repository of system-wide constants and parameters
 * @dev Abstract contract to be inherited by main protocol contracts
 */
abstract contract Constants {
    // ─────────────────────────────────────────────────────────────
    //  Role System (OpenZeppelin AccessControl compatible)
    // ─────────────────────────────────────────────────────────────
    
    /// @notice Role management using OpenZeppelin standard
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    // ─────────────────────────────────────────────────────────────
    //  Address System (EIP-55 compliant)
    // ─────────────────────────────────────────────────────────────

    /// @notice Test addresses with EIP-55 checksum compatibility
    address internal constant ALICE = 0xA11cE0000000000000000000000000000000000;
    address internal constant BOB = 0xB0b0000000000000000000000000000000000000;
    address internal constant CHARLIE = 0xC4A70000000000000000000000000000000000;
    address internal constant GOKU = 0x60C0710000000000000000000000000000000000;

    /// @notice Protocol contract addresses
    address internal constant REWARD_DISPATCHER = 0xD15DA7cC7D15DA7cC7D15DA7cC7D15DA7cC7D15D;

    /// @notice System addresses
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address internal constant ZERO_ADDRESS = address(0);

    // ─────────────────────────────────────────────────────────────
    //  Token Parameters
    // ─────────────────────────────────────────────────────────────

    /// @notice Token precision constants
    uint256 internal constant E18 = 1e18;  // Standard ERC20 precision
    uint256 internal constant E6 = 1e6;    // USDC-style precision

    /// @notice Token distribution parameters
    uint256 internal constant INITIAL_BALANCE = 1_000e18;         // 1,000 tokens
    uint256 internal constant BASE_USER_ALLOCATION = 10_000e18;   // 10k tokens
    uint256 internal constant WHALE_ALLOCATION = 1_000_000e18;    // 1M tokens
    uint256 internal constant PROTOCOL_RESERVES = 10_000_000e18;  // 10M tokens

    // ─────────────────────────────────────────────────────────────
    //  Time Parameters
    // ─────────────────────────────────────────────────────────────

    /// @notice Core time units
    uint256 internal constant MINUTE = 60 seconds;
    uint256 internal constant HOUR = 60 minutes;
    uint256 internal constant DAY = 24 hours;
    uint256 internal constant WEEK = 7 days;

    /// @notice Protocol timing parameters
    uint256 internal constant REWARD_EPOCH = 2 weeks;     // Reward distribution interval
    uint256 internal constant COOLDOWN_PERIOD = 10 days;  // Withdrawal preparation time
    uint256 internal constant UNSTAKE_WINDOW = 3 days;    // Active withdrawal period

    // ─────────────────────────────────────────────────────────────
    //  Mathematical Constants
    // ─────────────────────────────────────────────────────────────

    /// @notice Precision systems
    uint256 internal constant BPS_DENOMINATOR = 10_000;   // Basis Points (1 BPS = 0.01%)
    uint256 internal constant RATE_PRECISION = 1e18;      // 18 decimal precision

    /// @notice Safety limits
    uint256 internal constant MAX_UINT = type(uint256).max;
    uint256 internal constant MAX_INT = type(int256).max;

    /// @notice Percentage handling
    uint256 internal constant PCT_100 = BPS_DENOMINATOR;  // 100% = 10,000 BPS
    uint256 internal constant PCT_1 = 100;                // 1% = 100 BPS
}