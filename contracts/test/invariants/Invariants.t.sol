// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Setup} from "./Setup.t.sol"; // Inherit from Setup contract

/// @title StakerInvariants
/// @notice Echidna property checks for Staker contract
abstract contract Invariants is
    Setup // Inherit from Setup
{
    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                    CORE INVARIANTS                                        //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    function echidna_total_staked() public view override returns (bool) {
        uint256 total;
        for (uint256 i = 0; i < actors.length; i++) {
            total += staker.stakedBalanceOf(address(actors[i].proxy));
        }
        return staker.totalStaked() == total;
    }

    // function echidna_reward_integrity() public view returns (bool) {
    //     for (uint256 i = 0; i < rewardTokens.length; i++) {
    //         IStaker.Reward memory r = staker.rewards(address(rewardTokens[i]));
    //         uint256 contractBalance = rewardTokens[i].balanceOf(address(staker));

    //         uint256 maxPossible = r.rate * r.duration;
    //         uint256 elapsed = block.timestamp - r.lastUpdateTime;
    //         uint256 distributed = elapsed > r.duration ? maxPossible : r.rate * elapsed;

    //         if (contractBalance < (REWARD_AMOUNT - distributed)) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    function echidna_role_permissions() public view override returns (bool) {
        return staker.hasRole(staker.DEFAULT_ADMIN_ROLE(), admin) && staker.hasRole(staker.REWARDS_ADMIN_ROLE(), admin)
            && staker.hasRole(staker.PAUSE_GUARDIAN_ROLE(), PAUSE_GUARDIAN);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                    STATE CONSISTENCY                                      //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    function echidna_no_negative_stakes() public view returns (bool) {
        for (uint256 i = 0; i < actors.length; i++) {
            if (staker.stakedBalanceOf(address(actors[i].proxy)) > type(uint256).max) {
                return false;
            }
        }
        return true;
    }

    function echidna_reward_accrual() public view returns (bool) {
        for (uint256 i = 0; i < actors.length; i++) {
            for (uint256 j = 0; j < rewardTokens.length; j++) {
                uint256 earned = staker.earned(address(actors[i].proxy), address(rewardTokens[j]));
                if (earned > rewardTokens[j].balanceOf(address(staker))) {
                    return false;
                }
            }
        }
        return true;
    }
}
