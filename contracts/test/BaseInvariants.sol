// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// // Interfaces
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {Staking} from "src/Staking.sol";

// // Contracts
// //import {HandlerAggregator} from "../HandlerAggregator.t.sol";

// /// @title BaseInvariants
// /// @notice Implements protocol-wide invariants for staking contracts
// /// @dev Inherits `HandlerAggregator` to validate staking logic
// abstract contract BaseInvariants is HandlerAggregator {
//     function assert_BASE_INVARIANT_A(address stakingContract) internal {
//         uint256 totalStaked = Staking(stakingContract).totalStaked();
//         uint256 contractBalance = IERC20(Staking(stakingContract).stakingToken()).balanceOf(stakingContract);
//         assertEq(totalStaked, contractBalance, BASE_INVARIANT_A); // Ensure internal accounting matches contract balance
//     }

//     function assert_BASE_INVARIANT_B(address stakingContract, address rewardToken) internal {
//         uint256 totalRewardsAccrued = Staking(stakingContract).totalRewardsAccrued(rewardToken);
//         uint256 rewardBalance = IERC20(rewardToken).balanceOf(stakingContract);
//         assertGe(rewardBalance, totalRewardsAccrued, BASE_INVARIANT_B); // Ensure enough rewards to cover liabilities
//     }

//     function assert_BASE_INVARIANT_C(address stakingContract) internal {
//         uint256 rewardRate = Staking(stakingContract).rewardRate();
//         uint256 lastUpdateTime = Staking(stakingContract).lastUpdateTime();
//         if (lastUpdateTime == 0) {
//             assertEq(rewardRate, 0, BASE_INVARIANT_C); // No reward emissions before first update
//         }
//     }

//     function assert_BASE_INVARIANT_D(
//         address stakingContract,
//         address user
//     ) internal {
//         uint256 stakedBalance = Staking(stakingContract).stakedBalanceOf(user);
//         uint256 totalUserRewards = Staking(stakingContract).earned(user);

//         if (stakedBalance == 0) {
//             assertEq(totalUserRewards, 0, BASE_INVARIANT_D); // Users with zero stake should have zero rewards
//         }
//     }

//     function assert_BASE_INVARIANT_E(address stakingContract) internal {
//         uint256 totalStaked = Staking(stakingContract).totalStaked();
//         uint256 totalLiquidity = Staking(stakingContract).getLiquidity();
//         assertLe(totalStaked, totalLiquidity, BASE_INVARIANT_E); // Ensure protocol has enough liquidity to cover staked assets
//     }

//     function assert_BASE_INVARIANT_F(address stakingContract, address rewardToken) internal {
//         uint256 claimableRewards = Staking(stakingContract).totalClaimableRewards(rewardToken);
//         uint256 rewardBalance = IERC20(rewardToken).balanceOf(stakingContract);
//         assertLe(claimableRewards, rewardBalance, BASE_INVARIANT_F); // Ensure rewards are not over-promised
//     }

//     function assert_BASE_INVARIANT_G(address stakingContract, address user) internal {
//         bool isPaused = Staking(stakingContract).paused();
//         if (isPaused) {
//             uint256 stakedBalance = Staking(stakingContract).stakedBalanceOf(user);
//             assertEq(stakedBalance, 0, BASE_INVARIANT_G); // If paused, no one should have an active stake
//         }
//     }

//     function assert_BASE_INVARIANT_H(address stakingContract) internal {
//         assertFalse(Staking(stakingContract).reentrancyGuardEntered(), BASE_INVARIANT_H); // Ensure no reentrancy is active
//     }
// }
