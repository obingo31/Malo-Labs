// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BeforeAfter} from "./BeforeAfter.sol";
import {Asserts} from "@chimera/Asserts.sol";
import {Constants} from "./Constants.sol";

abstract contract Properties is Constants, BeforeAfter, Asserts {
    // ─────────────────────────────────────────────────────────────
    // 1. Solvency Property
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Ensure the contract remains solvent after any operation.
     * @dev Uses `gte` to assert that the contract has enough staking tokens to cover all staked balances.
     */
    function property_ContractSolvency() public returns (bool) {
        uint256 totalStakedBalance = staking.totalStaked();
        uint256 contractStakingTokenBalance = stakingToken.balanceOf(address(staking));

        // Contract should have enough staking tokens to cover all staked balances
        gte(contractStakingTokenBalance, totalStakedBalance, "Contract must remain solvent");
        return true;
    }

    // ─────────────────────────────────────────────────────────────
    // 2. Balance Consistency Property
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Ensure the sum of user balances equals the total staked amount.
     * @dev Uses `eq` to assert that the sum of user balances matches the total staked amount.
     */
    function property_BalanceConsistency() public returns (bool) {
        uint256 totalStakedBalance = staking.totalStaked();
        uint256 sumOfUserBalances = 0;

        // Use predefined actors from Constants.sol
        address[] memory actors = new address[](2);
        actors[0] = ALICE;
        actors[1] = BOB;

        for (uint256 i = 0; i < actors.length; i++) {
            sumOfUserBalances += staking.balanceOf(actors[i]);
        }

        // Sum of all user balances should equal the total staked amount
        eq(sumOfUserBalances, totalStakedBalance, "User balances must match total staked");
        return true;
    }

    // ─────────────────────────────────────────────────────────────
    // 3. Reward Integrity Property
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Ensure the total rewards distributed plus remaining rewards do not exceed the contract balance.
     * @dev Uses `lte` to assert that the total rewards distributed plus remaining rewards do not exceed the contract balance.
     */
    // function property_RewardIntegrity() public view returns (bool) {
    //     uint256 totalRewardsDistributed = staking.totalRewardsDistributed();
    //     // uint256 totalRewardsRemaining = staking.rewardTokensRemaining();
    //     uint256 contractRewardTokenBalance = maloToken.balanceOf(address(staking));

    //     // Total rewards distributed plus remaining rewards should not exceed contract balance
    //     lte(
    //         totalRewardsDistributed + totalRewardsRemaining,
    //         contractRewardTokenBalance,
    //         "Total rewards must not exceed contract balance"
    //     );
    //     return true;
    // }

    // ─────────────────────────────────────────────────────────────
    // 4. Reward Period State Property
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Ensure the reward period state is consistent.
     * @dev Uses `assertTrue` to verify that the reward rate is zero when the period has ended, or positive when active.
     */
    function property_RewardPeriodState() public view returns (bool) {
        uint256 periodFinish = staking.periodFinish();

        if (block.timestamp >= periodFinish) {
            // If period has ended, rewardRate should be zero
            assertTrue(staking.rewardRate() == 0, "Reward rate must be zero after period ends");
        } else {
            // If period is active, rewardRate should be positive
            assertTrue(staking.rewardRate() > 0, "Reward rate must be positive during active period");
        }
        return true;
    }
}
