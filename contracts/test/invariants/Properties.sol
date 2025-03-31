// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Asserts} from "@chimera/Asserts.sol";

import {BeforeAfter} from "./BeforeAfter.sol";
import {PropertiesSpecifications} from "./PropertiesSpecifications.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IStaking} from "src/interfaces/IStaking.sol";

abstract contract Properties is Asserts, PropertiesSpecifications, BeforeAfter {
    function property_STAKED_BALANCES() public updateGhosts returns (bool) {
        address[] memory actors = _getActors();
        uint256 totalStaked = 0;

        for (uint256 i = 0; i < actors.length; i++) {
            uint256 balance = staking.balanceOf(actors[i]);

            // Assert that the balance is non-negative
            gte(balance, 0, "STAKED_02: Balance must be non-negative");

            totalStaked += balance;
        }

        // Assert that the total staked matches the sum of individual balances
        eq(staking.totalStaked(), totalStaked, "STAKED_01: Total staked does not match individual balances");
        return true;
    }

    function property_REWARD_ACCOUNTING() public updateGhosts returns (bool) {
        if (staking.totalStaked() > 0) {
            uint256 timeElapsed = block.timestamp - _before.lastUpdateTime;
            uint256 calculatedRewards = timeElapsed * staking.rewardRate();

            // Assert that the rewards distributed match the calculated rewards
            eq(
                _after.totalRewardsDistributed - _before.totalRewardsDistributed,
                calculatedRewards,
                "REWARD_03: Rewards accounting mismatch"
            );
        } else {
            // Assert that rewards should not be distributed if no tokens are staked
            eq(
                _after.totalRewardsDistributed,
                _before.totalRewardsDistributed,
                "REWARD_04: Rewards distributed without any tokens staked"
            );
        }
        return true;
    }

    function property_FEE_HANDLING() public updateGhosts returns (bool) {
        // Assert that protocol fee does not exceed the maximum allowed fee
        lte(staking.protocolFee(), staking.MAX_FEE(), FEE_01);
        uint256 expectedFees =
            (_after.totalRewardsDistributed - _before.totalRewardsDistributed) * staking.protocolFee() / 1000;

        // Assert that the fee recipient's balance is updated correctly
        eq(
            staking.feeRecipient().balance,
            _before.feeRecipientBalance + expectedFees,
            "FEE_02: Fee recipient's balance mismatch"
        );
        return true;
    }

    function property_ACCESS_CONTROL() public updateGhosts returns (bool) {
        if (_after.protocolFee != _before.protocolFee) {
            t(staking.hasRole(staking.FEE_SETTER_ROLE(), address(this)), "ACCESS_02: Caller lacks FEE_SETTER_ROLE");
        }
        return true;
    }
}
