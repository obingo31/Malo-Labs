// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// // import {Properties} from "./Properties.sol";
// import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
// import {IHevm, vm} from "@chimera/Hevm.sol";
// import {IStaking} from "src/interfaces/IStaking.sol";
// import {ExpectedErrors} from "./ExpectedErrors.sol";
// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// abstract contract TargetFunctions is ExpectedErrors, Properties, BaseTargetFunctions {
//     constructor(address _staking, address _stakingToken, address _rewardToken) {
//         staking = IStaking(_staking);
//         stakingToken = ERC20(_stakingToken);
//         rewardToken = ERC20(_rewardToken);

//         // Initialize test actors
//         actors.push(address(0x1));
//         actors.push(address(0x2));
//         actors.push(address(0x3));
//     }

//     function setup() public {
//         for (uint256 i = 0; i < actors.length; i++) {
//             address actor = actors[i];
//             stakingToken.mint(actor, type(uint256).max / actors.length);
//             rewardToken.mint(actor, type(uint256).max / actors.length);

//             hevm.prank(actor);
//             stakingToken.approve(address(staking), type(uint256).max);

//             hevm.prank(actor);
//             rewardToken.approve(address(staking), type(uint256).max);
//         }
//     }

//     function handler_stake(uint256 amount) public {
//         address actor = _randomActor();
//         uint256 actorBalance = stakingToken.balanceOf(actor);
//         amount = _bound(amount, 1, actorBalance);

//         __before(actor);
//         hevm.prank(actor);
//         (bool success, bytes memory data) = address(staking).call(abi.encodeCall(IStaking.stake, (amount)));

//         if (!success) {
//             require(_isExpectedError(data, STAKE_ERRORS), "Unexpected stake error");
//         } else {
//             __after(actor);
//             require(
//                 _after.userStakingTokenBalance[actor] == _before.userStakingTokenBalance[actor] - amount,
//                 "STAKE_03: Token balance mismatch"
//             );
//             require(_after.userStakes[actor] == _before.userStakes[actor] + amount, "STAKE_01: Stake balance mismatch");
//             require(_after.totalStaked == _before.totalStaked + amount, "STAKE_02: Total staked mismatch");
//         }
//     }

//     function handler_unstake(uint256 amount) public {
//         address actor = _selectActorWithStake();
//         if (actor == address(0)) return;

//         uint256 actorStake = staking.balanceOf(actor);
//         amount = _bound(amount, 1, actorStake);

//         __before(actor);
//         hevm.prank(actor);
//         (bool success, bytes memory data) = address(staking).call(
//             abi.encodeCall(IStaking.unstake, (amount, "")) // Add empty bytes parameter
//         );

//         if (!success) {
//             require(_isExpectedError(data, WITHDRAW_ERRORS), "Unexpected unstake error");
//         } else {
//             __after(actor);
//             require(
//                 _after.userStakingTokenBalance[actor] == _before.userStakingTokenBalance[actor] + amount,
//                 "UNSTAKE_03: Token balance mismatch"
//             );
//             require(
//                 _after.userStakes[actor] == _before.userStakes[actor] - amount, "UNSTAKE_01: Stake balance mismatch"
//             );
//             require(_after.totalStaked == _before.totalStaked - amount, "UNSTAKE_02: Total staked mismatch");
//         }
//     }

//     function handler_claimRewards() public {
//         address actor = _selectActorWithRewards();
//         if (actor == address(0)) return;

//         __before(actor);
//         hevm.prank(actor);
//         (bool success, bytes memory data) = address(staking).call(abi.encodeCall(IStaking.claimRewards, ()));

//         if (!success) {
//             require(_isExpectedError(data, CLAIM_REWARD_ERRORS), "Unexpected claim error");
//         } else {
//             __after(actor);
//             uint256 expectedFee = (_before.userClaimableRewards[actor] * staking.protocolFee()) / 1000;
//             uint256 expectedNet = _before.userClaimableRewards[actor] - expectedFee;

//             require(
//                 _after.userRewardTokenBalance[actor] == _before.userRewardTokenBalance[actor] + expectedNet,
//                 "CLAIM_03: Reward balance mismatch"
//             );
//             require(_after.userClaimableRewards[actor] == 0, "CLAIM_01: Pending rewards not cleared");
//             require(
//                 _after.totalRewardsDistributed == _before.totalRewardsDistributed + expectedNet,
//                 "CLAIM_02: Total rewards mismatch"
//             );
//         }
//     }
// }
