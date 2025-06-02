//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// import {Setup} from "./Setup.sol";
// import {Strings, Pretty} from "./Pretty.sol";
import {StakingPostconditions} from "./StakingPostconditions.sol";
import {StakingInvariants} from "./StakingInvariants.sol";

/// @title Merged
/// @author Malo Labs
/// @notice This contract aggregates all the spec contracts for the staking system.
/// @notice Helper contract to aggregate all spec contracts, inherited in BaseHooks
/// @dev inherits StakingInvariants, StakingPostcondition
abstract contract Merged is StakingPostconditions, StakingInvariants {
// using Strings for string;
// using Pretty for uint256;
// using Pretty for bool;

// /// @notice Constructor to set up the spec aggregator
// constructor() {
//     // Initialize the spec contracts
//     _initializeInvariants();
//     _initializePostconditions();
// }

// /// @notice Function to initialize invariants
// function _initializeInvariants() internal {
//     // Add all invariants here
//     _addInvariant(invariant_CORE_INV_A);
//     _addInvariant(invariant_CORE_INV_B);
//     _addInvariant(invariant_CORE_INV_C);
//     _addInvariant(invariant_CORE_INV_D);
//     _addInvariant(invariant_REWARD_INV_A);
//     _addInvariant(invariant_LOCK_INV_A);
// }
// /// @notice Function to initialize postconditions

// function _initializePostconditions() internal {
//     // Add all postconditions here
//     _addPostcondition(postcondition_CORE_POST_A);
//     _addPostcondition(postcondition_CORE_POST_B);
//     _addPostcondition(postcondition_CORE_POST_C);
//     _addPostcondition(postcondition_REWARD_POST_A);
//     _addPostcondition(postcondition_LOCK_POST_A);
// }
// /// @notice Function to run all invariants

// function runInvariants() external {
//     for (uint256 i = 0; i < _invariants.length; i++) {
//         _invariants[i]();
//     }
// }
// /// @notice Function to run all postconditions

// function runPostconditions() external {
//     for (uint256 i = 0; i < _postconditions.length; i++) {
//         _postconditions[i]();
//     }
// }
}
