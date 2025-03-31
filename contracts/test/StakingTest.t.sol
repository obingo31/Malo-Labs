// // // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "src/StakingToken.sol";
// import "src/Staking.sol";

// contract StakingTest is Test {
//     StakingToken stakingToken;
//     Staking staking;
//     uint256 initialStakingAmount = 1000e18;
//     address user = address(0x123);
//     uint256 rewardPeriod = 30 days;
//     address rewardToken = address(0x456);
//     address feeRecipient = address(0x789);

//     function setUp() public {
// //         // Deploy the mintable ERC20 token
//         stakingToken = new StakingToken("StakingToken", "STK", address(this));

// //         // Mint some tokens to the contract
//         stakingToken.mint(address(this), initialStakingAmount);

// //         // Deploy the Staking contract with all the required arguments
//         staking = new Staking(address(stakingToken), address(this), rewardPeriod, feeRecipient);

//         // Give some tokens to the user
//         stakingToken.mint(user, initialStakingAmount);
//     }

//     function testStake() public {
//         uint256 amountToStake = 500e18;
//         uint256 userBalanceBefore = stakingToken.balanceOf(user);
//         uint256 stakingContractBalanceBefore = stakingToken.balanceOf(address(staking));

// //         // User stakes tokens
//         vm.startPrank(user);
//         stakingToken.approve(address(staking), amountToStake);
//         staking.stake(amountToStake);
//         vm.stopPrank();

//         uint256 userBalanceAfter = stakingToken.balanceOf(user);
//         uint256 stakingContractBalanceAfter = stakingToken.balanceOf(address(staking));

// //         // Assert that the balances have been updated correctly
//         assertEq(userBalanceBefore - amountToStake, userBalanceAfter);
//         assertEq(stakingContractBalanceBefore + amountToStake, stakingContractBalanceAfter);
//     }

//     function testWithdraw() public {
//         uint256 amountToStake = 500e18;
//         uint256 amountToWithdraw = 200e18;

// //         // Stake tokens first
//         vm.startPrank(user);
//         stakingToken.approve(address(staking), amountToStake);
//         staking.stake(amountToStake);
//         vm.stopPrank();

//         uint256 userBalanceBefore = stakingToken.balanceOf(user);
//         uint256 stakingContractBalanceBefore = stakingToken.balanceOf(address(staking));

// //         // Withdraw tokens
//         vm.startPrank(user);
//         staking.unstake(amountToWithdraw);
//         vm.stopPrank();

//         uint256 userBalanceAfter = stakingToken.balanceOf(user);
//         uint256 stakingContractBalanceAfter = stakingToken.balanceOf(address(staking));

// //         // Assert that the balances have been updated correctly
//         assertEq(userBalanceBefore + amountToWithdraw, userBalanceAfter);
//         assertEq(stakingContractBalanceBefore - amountToWithdraw, stakingContractBalanceAfter);
//     }
// }
