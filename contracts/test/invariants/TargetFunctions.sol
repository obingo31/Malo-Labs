// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Properties} from "./Properties.sol";
import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {IHevm, vm} from "@chimera/Hevm.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties {
    // ─────────────────────────────────────────────────────────────
    // Handler Functions
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Wrapper for the `stake` function.
     * @dev Ensures the user has sufficient staking tokens before staking.
     * @param amount The amount of tokens to stake.
     */
    function handler_stake(uint256 amount) external {
        // Ensure the user has sufficient staking tokens
        uint256 userBalance = stakingToken.balanceOf(msg.sender);
        if (amount > userBalance) {
            amount = userBalance; 
        }

        // Ensure the amount is greater than zero
        if (amount == 0) {
            return; // Skip if the user has no tokens to stake
        }

        // Stake the tokens
        vm.prank(msg.sender);
        staking.stake(amount);
    }

    /**
     * @notice Wrapper for the `withdraw` function.
     * @dev Ensures the user has sufficient staked tokens before withdrawing.
     * @param amount The amount of tokens to withdraw.
     */
    function handler_withdraw(uint256 amount) external {
        // Ensure the user has sufficient staked tokens
        uint256 stakedBalance = staking.balanceOf(msg.sender);
        if (amount > stakedBalance) {
            amount = stakedBalance; // Cap the amount to the user's staked balance
        }

        // Ensure the amount is greater than zero
        if (amount == 0) {
            return; // Skip if the user has no tokens to withdraw
        }

        // Withdraw the tokens
        vm.prank(msg.sender);
        staking.withdraw(amount);
    }

    /**
     * @notice Wrapper for the `claimRewards` function.
     * @dev Ensures the user has rewards to claim before calling the function.
     */
    function handler_claimRewards() external {
        // Ensure the user has rewards to claim
        uint256 rewardsEarned = staking.earned(msg.sender);
        if (rewardsEarned == 0) {
            return; // Skip if the user has no rewards to claim
        }

        // Claim the rewards
        vm.prank(msg.sender);
        staking.claimRewards();
    }

    /**
     * @notice Wrapper for the `setRewardRate` function.
     * @dev Ensures the reward rate is set only by the rewards distributor.
     * @param rewardRate The new reward rate.
     */
    function handler_setRewardRate(uint256 rewardRate) external {
        // Ensure the caller is the rewards distributor
        vm.prank(address(this)); // Simulate rewards distributor
        staking.setRewardRate(rewardRate);
    }

    /**
     * @notice Wrapper for the `setProtocolFee` function.
     * @dev Ensures the protocol fee is set only by the fee setter.
     * @param fee The new protocol fee.
     */
    function handler_setProtocolFee(uint256 fee) external {
        // Ensure the caller has the FEE_SETTER_ROLE
        vm.prank(address(this)); // Simulate fee setter
        staking.setProtocolFee(fee);
    }

    /**
     * @notice Wrapper for the `setFeeRecipient` function.
     * @dev Ensures the fee recipient is set only by the fee setter.
     * @param recipient The new fee recipient.
     */
    function handler_setFeeRecipient(address recipient) external {
        // Ensure the caller has the FEE_SETTER_ROLE
        vm.prank(address(this)); // Simulate fee setter
        staking.setFeeRecipient(recipient);
    }

    /**
     * @notice Wrapper for the `emergencyWithdraw` function.
     * @dev Ensures the contract is paused before allowing emergency withdrawals.
     */
    function handler_emergencyWithdraw() external {
        // Ensure the contract is paused
        if (!staking.paused()) {
            return; // Skip if the contract is not paused
        }

        // Perform emergency withdrawal
        vm.prank(msg.sender);
        staking.emergencyWithdraw();
    }
}
