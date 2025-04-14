// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contracts
import {Staker} from "../../src/Staker.sol";
import {Actor} from "./Actor.sol";

// Mock Contracts
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

/// @notice BaseStorage contract for Staker invariant tests
abstract contract BaseStorage {
    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                       CONSTANTS                                           //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    uint256 internal constant MAX_REWARD_AMOUNT = 1e30;
    uint256 internal constant INITIAL_ETH_BALANCE = 1 ether;
    uint256 internal constant INITIAL_STAKE_BALANCE = 1e24;
    uint256 internal constant REWARD_DURATION = 7 days;
    uint256 internal constant NUMBER_OF_ACTORS = 3;

    address internal constant ADMIN = address(0xAd01);
    address internal constant PAUSE_GUARDIAN = address(0x6a8d);
    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                          ACTORS                                           //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Stores the actor during a handler call
    Actor internal activeActor;

    /// @notice Mapping of user addresses to actor proxies
    mapping(address => Actor) internal actors;

    /// @notice Array of all actor addresses
    address[] internal actorAddresses;

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                       PROTOCOL STATE                                      //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Main Staker contract
    Staker public staker;

    /// @notice Staking token
    ERC20Mock public stakingToken;

    /// @notice Array of reward tokens
    ERC20Mock[] public rewardTokens;

    /// @notice Track protected roles
    struct Roles {
        address admin;
        address pauseGuardian;
    }

    Roles internal roles;

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                       TESTING STATE                                       //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Track reward configurations
    struct RewardConfig {
        address token;
        uint256 amount;
        uint256 duration;
    }

    RewardConfig[] internal rewardConfigs;

    /// @notice Track initial balances
    struct InitialBalances {
        uint256 stakingToken;
        uint256[] rewardTokens;
    }

    mapping(address => InitialBalances) internal initialBalances;

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                       MOCKS & HELPERS                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Array of all supported tokens
    address[] internal allTokens;

    /// @notice Track actor approvals
    struct Approvals {
        address token;
        address spender;
        uint256 amount;
    }

    mapping(address => Approvals[]) internal actorApprovals;
}
