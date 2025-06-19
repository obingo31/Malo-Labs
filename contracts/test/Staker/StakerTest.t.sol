// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Staker} from "../../src/Staker.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Reverter, ReverterWithDecimals} from "../utils/Reverter.sol";

contract StakerTest is Test {
    event RewardsDurationUpdated(address indexed token, uint256 newDuration);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed token, uint256 reward);
    event RewardAdded(address indexed token, uint256 amount, uint256 duration);

    address internal OWNER = vm.addr(uint256(keccak256(bytes("Owner"))));
    address internal PAUSE_GUARDIAN = vm.addr(uint256(keccak256(bytes("Guardian"))));

    Staker internal staker;
    MockERC20 internal stakingToken;
    MockERC20 internal rewardToken1;
    MockERC20 internal rewardToken2;

    function setUp() public {
        vm.warp(1_641_070_800);
        vm.startPrank(OWNER);

        // Create tokens
        stakingToken = new MockERC20("Staking Token", "STK");
        rewardToken1 = new MockERC20("Reward Token 1", "RT1");
        rewardToken2 = new MockERC20("Reward Token 2", "RT2");

        // Create staker contract
        staker = new Staker(address(stakingToken), OWNER, PAUSE_GUARDIAN);

        // Grant rewards admin role to owner
        staker.grantRole(staker.REWARDS_ADMIN_ROLE(), OWNER);

        vm.stopPrank();
    }

    // Helper function to add rewards
    function _addReward(address token, uint256 amount, uint256 duration) private {
        // Mint tokens to OWNER and approve
        MockERC20(token).mint(OWNER, amount);
        vm.prank(OWNER);
        IERC20(token).approve(address(staker), amount);

        // Add reward
        vm.prank(OWNER);
        staker.addReward(token, amount, duration);
    }

    // Test adding reward token that always reverts
    // forge test --match-contract StakerTest --match-test test_addRewardTokenThatAlwaysReverts -vvv
    function test_addRewardTokenThatAlwaysReverts() public {
        Reverter reverterToken = new Reverter();

        vm.startPrank(OWNER);
        vm.expectRevert("Reverter: I am a contract that always reverts");
        staker.addReward(address(reverterToken), 1000 ether, 30 days);
        vm.stopPrank();
    }

    // Test initial state
    // forge test --match-contract StakerTest --match-test test_staker_initialState -vvv
    function test_staker_initialState() public {
        assertEq(address(staker.stakingToken()), address(stakingToken), "Staking token mismatch");
        assertTrue(staker.hasRole(staker.DEFAULT_ADMIN_ROLE(), OWNER), "Owner should have admin role");
        assertTrue(staker.hasRole(staker.PAUSE_GUARDIAN_ROLE(), PAUSE_GUARDIAN), "Guardian should have pause role");
    }

    // Test adding reward token
    // forge test --match-contract StakerTest --match-test  test_addReward -vvv
    function test_addReward() public {
        uint256 amount = 1000 ether;
        uint256 duration = 30 days;

        rewardToken1.mint(OWNER, amount);
        vm.prank(OWNER);
        rewardToken1.approve(address(staker), amount);

        vm.startPrank(OWNER);
        vm.expectEmit(true, true, true, true, address(staker));
        emit RewardAdded(address(rewardToken1), amount, duration);
        staker.addReward(address(rewardToken1), amount, duration);
        vm.stopPrank();
    }

    // Test staking
    // forge test --match-contract StakerTest --match-test test_stake -vvv
    function test_stake() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 1000 ether;
        uint256 duration = 30 days;

        // Setup reward
        _addReward(address(rewardToken1), rewardAmount, duration);

        // Stake tokens
        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staker), stakeAmount);

        vm.expectEmit();
        emit Staked(address(this), stakeAmount);
        staker.stake(stakeAmount);

        assertEq(staker.stakedBalanceOf(address(this)), stakeAmount, "Staked balance mismatch");
        assertEq(staker.totalStaked(), stakeAmount, "Total staked mismatch");
    }

    // Test claiming rewards
    // forge test --match-contract StakerTest --match-test test_claimRewards -vvv
    function test_claimRewards() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 1000 ether;
        uint256 duration = 30 days;

        _addReward(address(rewardToken1), rewardAmount, duration);

        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staker), stakeAmount);
        staker.stake(stakeAmount);

        vm.warp(block.timestamp + duration / 2);

        uint256 expectedReward = rewardAmount / 2;
        vm.expectEmit();
        emit RewardPaid(address(this), address(rewardToken1), expectedReward);
        staker.claimRewards(address(rewardToken1));

        assertEq(rewardToken1.balanceOf(address(this)), expectedReward, "Reward amount mismatch");
    }

    // Test withdrawing
    // forge test --match-contract StakerTest --match-test test_withdraw -vvv
    function test_withdraw() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 1000 ether;
        uint256 duration = 30 days;

        _addReward(address(rewardToken1), rewardAmount, duration);

        // Stake tokens
        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staker), stakeAmount);
        staker.stake(stakeAmount);

        vm.expectEmit(true, true, false, true, address(staker));
        emit Withdrawn(address(this), stakeAmount);

        // Withdraw
        staker.withdraw(stakeAmount);

        // Verify withdrawal
        assertEq(staker.stakedBalanceOf(address(this)), 0, "Staked balance should be zero");
        assertEq(stakingToken.balanceOf(address(this)), stakeAmount, "Tokens not returned");
    }

    // Test pausing
    // forge test --match-contract StakerTest --match-test test_pause -vvv
    function test_pause() public {
        vm.prank(PAUSE_GUARDIAN);
        staker.pause();
        assertTrue(staker.paused(), "Contract should be paused");

        // Unpause as guardian
        vm.prank(PAUSE_GUARDIAN);
        staker.unpause();
        assertFalse(staker.paused(), "Contract should be unpaused");
    }

    // Test multiple reward tokens
    // forge test --match-contract StakerTest --match-test test_multipleRewardTokens -vvv
    function test_multipleRewardTokens() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount1 = 1000 ether;
        uint256 rewardAmount2 = 2000 ether;
        uint256 duration = 30 days;

        // Setup rewards
        _addReward(address(rewardToken1), rewardAmount1, duration);
        _addReward(address(rewardToken2), rewardAmount2, duration);

        // Stake tokens
        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staker), stakeAmount);
        staker.stake(stakeAmount);

        // Advance time
        vm.warp(block.timestamp + duration / 2);

        // Claim rewards
        uint256 expectedReward1 = rewardAmount1 / 2;
        uint256 expectedReward2 = rewardAmount2 / 2;

        staker.claimRewards(address(rewardToken1));
        staker.claimRewards(address(rewardToken2));

        // Verify rewards with 0.0001% tolerance
        assertApproxEqRel(
            rewardToken1.balanceOf(address(this)),
            expectedReward1,
            1e14, // 0.0001% tolerance (1e14 / 1e18 = 0.0001)
            "Reward 1 incorrect"
        );

        assertApproxEqRel(
            rewardToken2.balanceOf(address(this)),
            expectedReward2,
            1e14, // 0.0001% tolerance
            "Reward 2 incorrect"
        );
    }

    // Test claim all rewards
    // forge test --match-contract StakerTest --match-test test_claimAllRewards -vvv
    function test_claimAllRewards() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount1 = 1000 ether;
        uint256 rewardAmount2 = 2000 ether;
        uint256 duration = 30 days;

        // Setup rewards
        _addReward(address(rewardToken1), rewardAmount1, duration);
        _addReward(address(rewardToken2), rewardAmount2, duration);

        // Stake tokens
        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staker), stakeAmount);
        staker.stake(stakeAmount);

        // Advance time
        vm.warp(block.timestamp + duration / 2);

        // Claim all rewards
        staker.claimAllRewards();

        // Use a small tolerance for rounding
        assertApproxEqRel(
            rewardToken1.balanceOf(address(this)),
            rewardAmount1 / 2,
            1e14, // 0.0001% tolerance
            "Reward 1 amount mismatch"
        );
        assertApproxEqRel(
            rewardToken2.balanceOf(address(this)),
            rewardAmount2 / 2,
            1e14, // 0.0001% tolerance
            "Reward 2 amount mismatch"
        );
    }

    // Test staking with reverting token
    // forge test --match-contract StakerTest --match-test test_stakeWithRevertingToken -vvv
    function test_stakeWithRevertingToken() public {
        Reverter revertingToken = new Reverter();

        vm.startPrank(OWNER);

        // we deploy a new Staker using the Reverter as the staking token
        Staker localStaker = new Staker(address(revertingToken), OWNER, PAUSE_GUARDIAN);

        // Grant roles as OWNER
        localStaker.grantRole(localStaker.REWARDS_ADMIN_ROLE(), OWNER);

        vm.stopPrank();
        vm.startPrank(address(this));
        vm.expectRevert("Reverter: I am a contract that always reverts");
        localStaker.stake(1 ether);
        vm.stopPrank();
    }

    // Tests if withdraw reverts correctly when invalid amount
    // forge test --match-contract StakerTest --match-test test_withdraw_when_invalidAmount -vvv
    function test_withdraw_when_invalidAmount() public {
        vm.expectRevert(bytes("Cannot withdraw 0 or stake 0"));
        staker.withdraw(0);
    }

    // Tests if claim rewards reverts correctly when invalid token
    // forge test --match-contract StakerTest --match-test test_claimRewards_when_invalidToken
    function test_claimRewards_when_invalidToken() public {
        vm.expectRevert(bytes("Invalid reward token"));
        staker.claimRewards(address(0));
    }

    // Tests if claimRewards reverts correctly when there are no rewards to claim
    // forge test --match-contract StakerTest --match-test test_claimRewards_when_noRewardsToClaim
    function test_claimRewards_when_noRewardsToClaim() public {
        // Stake some tokens first
        uint256 stakeAmount = 100 ether;
        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staker), stakeAmount);
        staker.stake(stakeAmount);
        // Attempt to claim rewards without any rewards added
        vm.expectRevert(bytes("Invalid reward token"));
        staker.claimRewards(address(rewardToken1));
    }

    // Tests if claimRewards fails if user has already withdrawn
    // forge test --match-contract StakerTest --match-test test_claimRewards_when_alreadyWithdrawn
    function test_claimRewards_when_alreadyWithdrawn() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 1000 ether;
        uint256 duration = 30 days;
        _addReward(address(rewardToken1), rewardAmount, duration);

        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staker), stakeAmount);
        staker.stake(stakeAmount);
        // Withdraw before claiming rewards
        staker.withdraw(stakeAmount);
        // Attempt to claim rewards after withdrawal
        vm.expectRevert(bytes("No rewards to claim"));
        staker.claimRewards(address(rewardToken1));
    }

    // Tests if withdraw works correctly when authorized
    // forge test --match-contract StakerTest --match-test test_withdraw_when_authorized -vvv
    function test_withdraw_when_authorized() public {
        uint256 stakeAmount = 100 ether;
        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staker), stakeAmount);
        staker.stake(stakeAmount);
        vm.expectEmit(true, true, false, true, address(staker));
        emit Withdrawn(address(this), stakeAmount);
        staker.withdraw(stakeAmount);
        assertEq(staker.stakedBalanceOf(address(this)), 0, "Staked balance mismatch after withdrawal");
        assertEq(stakingToken.balanceOf(address(this)), stakeAmount, "Tokens not returned after withdrawal");
    }
}
