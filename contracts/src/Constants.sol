// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProtocolConstants
 * @notice Central repository of system-wide constants and parameters
 * @dev Abstract contract to be inherited by main protocol contracts
 */
abstract contract Constants {
    // ─────────────────────────────────────────────────────────────
    //  Role System (OpenZeppelin AccessControl compatible)
    // ─────────────────────────────────────────────────────────────

    /// @notice Role for managing fee parameters
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    /// @notice Role for collecting protocol fees
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");

    /// @notice Role for developer maintenance operations
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    /// @notice Role for pausing contract operations
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role for governance decisions
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    // ─────────────────────────────────────────────────────────────
    //  Mathematical Constants
    // ─────────────────────────────────────────────────────────────

    /// @notice Precision factor for decimal calculations (1e18)
    uint256 public constant PRECISION_FACTOR = 1e18;

    /// @notice Basis points denominator (10000 = 100%)
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @notice Precision for rate calculations (1e18)
    uint256 public constant RATE_PRECISION = 1e18;

    // ─────────────────────────────────────────────────────────────
    //  Protocol Parameters
    // ─────────────────────────────────────────────────────────────

    /// @notice Initial reward distribution epoch duration
    uint256 public constant REWARD_EPOCH = 2 weeks;

    /// @notice Cooldown period after unstaking initiation
    uint256 public constant COOLDOWN_PERIOD = 10 days;

    /// @notice Window to complete unstaking after cooldown
    uint256 public constant UNSTAKE_WINDOW = 3 days;

    /// @notice Maximum protocol fee percentage (100% = 10000 BPS)
    uint256 public constant MAX_PROTOCOL_FEE_BPS = 3000; // 30%

    // ─────────────────────────────────────────────────────────────
    //  System Addresses
    // ─────────────────────────────────────────────────────────────

    /// @notice Burn address for token destruction
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @notice Zero address placeholder
    address public constant ZERO_ADDRESS = address(0);

    /// @notice Default reward distribution address
    address public constant REWARD_DISPATCHER = 0xd15Da7cc7d15Da7CC7D15dA7Cc7d15Da7cc7D15d;

    // ─────────────────────────────────────────────────────────────
    //  Token Parameters
    // ─────────────────────────────────────────────────────────────

    /// @notice Standard ERC20 decimal precision (1e18)
    uint256 public constant TOKEN_PRECISION = 1e18;

    /// @notice Initial protocol reserve allocation
    uint256 public constant PROTOCOL_RESERVES = 10_000_000e18;
}
