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

    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    // ─────────────────────────────────────────────────────────────
    //  Address System (EIP-55 compliant)
    // ─────────────────────────────────────────────────────────────
    address internal constant ALICE = 0xA11Ce00000000000000000000000000000000000;
    address internal constant BOB = 0xB0b0000000000000000000000000000000000000;
    address internal constant CHARLIE = 0xc4A7000000000000000000000000000000000000;
    address internal constant GOKU = 0x60C0710000000000000000000000000000000000;

    address internal constant REWARD_DISPATCHER = 0xd15Da7cc7d15Da7CC7D15dA7Cc7d15Da7cc7D15d;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address internal constant ZERO_ADDRESS = address(0);

    // ─────────────────────────────────────────────────────────────
    //  Token Parameters
    // ─────────────────────────────────────────────────────────────
    uint256 internal constant E18 = 1e18;
    uint256 internal constant E6 = 1e6;
    uint256 public constant PRECISION_FACTOR = 1e18;

    uint256 internal constant INITIAL_BALANCE = 1_000e18;
    uint256 internal constant BASE_USER_ALLOCATION = 10_000e18;
    uint256 internal constant WHALE_ALLOCATION = 1_000_000e18;
    uint256 internal constant PROTOCOL_RESERVES = 10_000_000e18;

    // ─────────────────────────────────────────────────────────────
    //  Time Parameters
    // ─────────────────────────────────────────────────────────────
    uint256 internal constant MINUTE = 60 seconds;
    uint256 internal constant HOUR = 60 minutes;
    uint256 internal constant DAY = 24 hours;
    uint256 internal constant WEEK = 7 days;

    uint256 internal constant REWARD_EPOCH = 2 weeks;
    uint256 internal constant COOLDOWN_PERIOD = 10 days;
    uint256 internal constant UNSTAKE_WINDOW = 3 days;

    // ─────────────────────────────────────────────────────────────
    //  Mathematical Constants
    // ─────────────────────────────────────────────────────────────
    uint256 internal constant BPS_DENOMINATOR = 10_000;
    uint256 internal constant RATE_PRECISION = 1e18;

    uint256 internal constant MAX_UINT = type(uint256).max;
    uint256 internal constant MAX_INT = uint256(type(int256).max);

    uint256 internal constant PCT_100 = BPS_DENOMINATOR;
    uint256 internal constant PCT_1 = 100;

    // ─────────────────────────────────────────────────────────────
    //  Testing Constants
    // ─────────────────────────────────────────────────────────────
    address internal constant HEVM_ADDRESS = address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
}
