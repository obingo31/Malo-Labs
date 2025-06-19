// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import "forge-std/console.sol";

import "../../src/Staker.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract StakerPropertyTest is StdInvariant, Test {
    Staker public staker;
    MockERC20 public stakingToken;
    MockERC20 public rewardToken;
    MockERC20 public rewardToken1;
    MockERC20 public rewardToken2;
    address public user1 = address(1);
    address public user2 = address(2);
    address public rewardAdmin = address(3);

    constructor() {
        stakingToken = new MockERC20("Staking Token", "STK");
        rewardToken = new MockERC20("Reward Token", "RWD");
        rewardToken1 = new MockERC20("Reward Token 1", "RWD1");
        rewardToken2 = new MockERC20("Reward Token 2", "RWD2");
        staker = new Staker(address(stakingToken), address(this), address(this));

        // Set up roles
        vm.startPrank(address(this));
        staker.grantRole(staker.REWARDS_ADMIN_ROLE(), rewardAdmin);
        vm.stopPrank();

        // Mint tokens to users
        uint256 mintAmount = 1000 ether;
        stakingToken.mint(user1, mintAmount);
        stakingToken.mint(user2, mintAmount);
        rewardToken.mint(rewardAdmin, type(uint256).max);

        // Register contract for invariant testing
        targetContract(address(staker));
    }

    // forge test --match-contract StakerPropertyTest --match-test invariantTotalStakedNeverExceedsSupply
    // Invariant: Total staked amount never exceeds total supply
    function invariantTotalStakedNeverExceedsSupply() public {
        uint256 totalStaked = staker.totalStaked();
        uint256 totalSupply = stakingToken.totalSupply();
        assertLe(totalStaked, totalSupply, "Total staked exceeds total supply");
    }

    // forge test --match-contract StakerPropertyTest --match-test invariantuserStakedNeverExceedsBalance
    // Invariant: User staked balance never exceeds their total balance
    function invariantuserStakedNeverExceedsBalance() public {
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 userBalance = stakingToken.balanceOf(user);
            uint256 userStaked = staker.stakedBalanceOf(user);
            assertLe(userStaked, userBalance, "User staked more than their balance");
        }
    }

    // forge test --match-contract StakerPropertyTest --match-test testrewardProportionality
    // Property: Reward calculation is proportional to stake amount
    function testrewardProportionality(uint256 stake1, uint256 stake2) public {
        // Bound stakes to safe ranges
        stake1 = bound(stake1, 1e18, 100e18);
        stake2 = bound(stake2, 1e18, 100e18);

        // Approve staking
        vm.prank(user1);
        stakingToken.approve(address(staker), stake1);
        vm.prank(user2);
        stakingToken.approve(address(staker), stake2);

        // Stake tokens
        vm.prank(user1);
        staker.stake(stake1);
        vm.prank(user2);
        staker.stake(stake2);

        // Add rewards
        uint256 rewardAmount = 100e18;
        uint256 duration = 100;
        vm.startPrank(rewardAdmin);
        rewardToken.approve(address(staker), rewardAmount);
        staker.addReward(address(rewardToken), rewardAmount, duration);
        vm.stopPrank();

        // Advance time
        vm.warp(block.timestamp + duration / 2);

        // Calculate expected rewards with fixed-point math
        uint256 totalStaked = stake1 + stake2;
        uint256 expectedReward1 = (rewardAmount * stake1 * (duration / 2)) / (totalStaked * duration);
        uint256 expectedReward2 = (rewardAmount * stake2 * (duration / 2)) / (totalStaked * duration);

        // Check rewards
        assertApproxEqRel(staker.earned(user1, address(rewardToken)), expectedReward1, 1e16);

        assertApproxEqRel(staker.earned(user2, address(rewardToken)), expectedReward2, 1e16);
    }

    // forge test --match-contract StakerPropertyTest --match-test testrewardTimeWeighting
    // Property: Reward calculation is time-weighted
    function testrewardTimeWeighting(uint256 stakeAmount, uint256 timeElapsed) public {
        // Bound inputs
        stakeAmount = bound(stakeAmount, 10e18, 100e18);
        timeElapsed = bound(timeElapsed, 1 days, 7 days);
        uint256 rewardDuration = 10 days;

        // Approve and stake
        vm.prank(user1);
        stakingToken.approve(address(staker), stakeAmount);
        vm.prank(user1);
        staker.stake(stakeAmount);

        // Add rewards
        uint256 rewardAmount = 1000e18;
        vm.startPrank(rewardAdmin);
        rewardToken.approve(address(staker), rewardAmount);
        staker.addReward(address(rewardToken), rewardAmount, rewardDuration);
        vm.stopPrank();

        // Advance time
        vm.warp(block.timestamp + timeElapsed);

        // Calculate expected reward
        uint256 expectedReward = (rewardAmount * timeElapsed) / rewardDuration;

        // Check reward
        assertApproxEqRel(
            staker.earned(user1, address(rewardToken)), expectedReward, 1e16, "Reward not properly time-weighted"
        );
    }
}
