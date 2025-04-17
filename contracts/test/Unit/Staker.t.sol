// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/Staker.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Actor} from "../InvariantTests/Actor.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {IStaker} from "src/interfaces/IStaker.sol";
import {console} from "forge-std/console.sol";

contract StakerTest is Test {
    Staker public staker;
    MockERC20 public stakingToken;
    MockERC20 public rewardToken1;
    MockERC20 public rewardToken2;

    address public admin = address(1);
    address public pauseGuardian = address(2);
    address public user1 = address(3);
    address public user2 = address(4);

    uint256 constant INITIAL_BALANCE = 1000 ether;
    uint256 constant STAKE_AMOUNT = 100 ether;
    uint256 constant REWARD_AMOUNT = 500 ether;
    uint256 constant REWARD_DURATION = 100; // 100 seconds

    // Use our Actor contract to test protected functions
    Actor public adminActor;
    Actor public guardianActor;
    Actor public user1Actor;
    Actor public user2Actor;

    function setUp() public {
        // Deploy mock tokens
        stakingToken = new MockERC20("Staking Token", "STK");
        rewardToken1 = new MockERC20("Reward Token 1", "RWD1");
        rewardToken2 = new MockERC20("Reward Token 2", "RWD2");

        // Deploy staker contract
        vm.prank(admin);
        staker = new Staker(address(stakingToken), admin, pauseGuardian);

        // Mint tokens to users and admin
        stakingToken.mint(user1, INITIAL_BALANCE);
        stakingToken.mint(user2, INITIAL_BALANCE);
        rewardToken1.mint(admin, INITIAL_BALANCE);
        rewardToken2.mint(admin, INITIAL_BALANCE);

        // Setup Actor contracts for different roles
        address[] memory tokens = new address[](3);
        tokens[0] = address(stakingToken);
        tokens[1] = address(rewardToken1);
        tokens[2] = address(rewardToken2);

        address[] memory contracts = new address[](1);
        contracts[0] = address(staker);

        adminActor = new Actor(tokens, contracts);
        guardianActor = new Actor(tokens, contracts);
        user1Actor = new Actor(tokens, contracts);
        user2Actor = new Actor(tokens, contracts);

        stakingToken.mint(address(user1Actor), INITIAL_BALANCE);
        stakingToken.mint(address(user2Actor), INITIAL_BALANCE);
        rewardToken1.mint(address(adminActor), INITIAL_BALANCE);
        rewardToken2.mint(address(adminActor), INITIAL_BALANCE);

        // Grant roles to actors
        vm.startPrank(admin);
        staker.grantRole(staker.DEFAULT_ADMIN_ROLE(), address(adminActor));
        staker.grantRole(staker.REWARDS_ADMIN_ROLE(), address(adminActor));
        staker.grantRole(staker.PAUSE_GUARDIAN_ROLE(), address(guardianActor));
        vm.stopPrank();
    }

    // Helper function to add a reward token
    function _addReward(address token, uint256 amount, uint256 duration) internal {
        // Approve token
        vm.startPrank(address(adminActor));
        MockERC20(token).approve(address(staker), amount);

        // Add reward token
        bytes memory callData = abi.encodeWithSelector(staker.addReward.selector, token, amount, duration);
        adminActor.proxy(address(staker), callData);
        vm.stopPrank();
    }

    // forge test --match-contract StakerTest --match-test testStake ✔️
    function testStake() public {
        // User approves tokens for staking
        vm.prank(address(user1Actor));
        stakingToken.approve(address(staker), STAKE_AMOUNT);

        // User stakes tokens
        vm.prank(address(user1Actor));
        bytes memory callData = abi.encodeWithSelector(staker.stake.selector, STAKE_AMOUNT);
        user1Actor.proxy(address(staker), callData);

        // Verify balances
        assertEq(staker.stakedBalanceOf(address(user1Actor)), STAKE_AMOUNT);
        assertEq(staker.totalStaked(), STAKE_AMOUNT);
        assertEq(stakingToken.balanceOf(address(staker)), STAKE_AMOUNT);
    }

    // forge test --match-contract StakerTest --match-test testStake ✔️
    function testWithdraw() public {
        // First stake tokens
        vm.startPrank(address(user1Actor));
        stakingToken.approve(address(staker), STAKE_AMOUNT);
        bytes memory stakeCallData = abi.encodeWithSelector(staker.stake.selector, STAKE_AMOUNT);
        user1Actor.proxy(address(staker), stakeCallData);
        vm.stopPrank();

        // Now withdraw them
        vm.prank(address(user1Actor));
        bytes memory withdrawCallData = abi.encodeWithSelector(staker.withdraw.selector, STAKE_AMOUNT);
        user1Actor.proxy(address(staker), withdrawCallData);

        // Verify balances
        assertEq(staker.stakedBalanceOf(address(user1Actor)), 0);
        assertEq(staker.totalStaked(), 0);
        assertEq(stakingToken.balanceOf(address(user1Actor)), INITIAL_BALANCE);
    }

    // forge test --match-contract StakerTest --match-test testAddReward ✔️
    function testAddReward() public {
        uint256 amount = REWARD_AMOUNT;
        uint256 duration = REWARD_DURATION;

        _addReward(address(rewardToken1), amount, duration);

        assertTrue(staker.isRewardToken(address(rewardToken1)));

        (uint256 rewardDuration, uint256 rate, uint256 lastUpdateTime,) = staker.rewards(address(rewardToken1));

        assertEq(rewardDuration, duration);
        assertEq(rate, amount / duration);
        assertEq(lastUpdateTime, block.timestamp);
    }

    // forge test --match-contract StakerTest --match-test testEarnAndClaimRewards ✔️
    // Test earning and claiming rewards
    function testEarnAndClaimRewards() public {
        // Add reward
        _addReward(address(rewardToken1), REWARD_AMOUNT, REWARD_DURATION);

        vm.startPrank(address(user1Actor));
        stakingToken.approve(address(staker), STAKE_AMOUNT);
        bytes memory stakeCallData = abi.encodeWithSelector(staker.stake.selector, STAKE_AMOUNT);
        user1Actor.proxy(address(staker), stakeCallData);
        vm.stopPrank();

        vm.warp(block.timestamp + REWARD_DURATION / 2);

        uint256 expectedReward = (REWARD_AMOUNT / 2);
        uint256 earned = staker.earned(address(user1Actor), address(rewardToken1));
        assertApproxEqRel(earned, expectedReward, 0.01e18); // 1% tolerance

        // Claim rewards
        vm.prank(address(user1Actor));
        bytes memory claimCallData = abi.encodeWithSelector(staker.claimRewards.selector, address(rewardToken1));
        user1Actor.proxy(address(staker), claimCallData);

        // Verify rewards were transferred
        assertApproxEqRel(
            rewardToken1.balanceOf(address(user1Actor)),
            expectedReward,
            0.01e18 // 1% tolerance
        );
    }

    // forge test --match-contract StakerTest --match-test testRemoveRewardToken ✔️
    function testRemoveRewardToken() public {
        // Add reward
        _addReward(address(rewardToken1), REWARD_AMOUNT, REWARD_DURATION);

        vm.warp(block.timestamp + REWARD_DURATION + 1);

        vm.prank(address(adminActor));
        bytes memory removeCallData = abi.encodeWithSelector(staker.removeRewardToken.selector, address(rewardToken1));
        adminActor.proxy(address(staker), removeCallData);

        assertFalse(staker.isRewardToken(address(rewardToken1)));
    }

    // forge test --match-contract StakerTest --match-test testMultipleRewardTokens ✔️
    function testMultipleRewardTokens() public {
        // Add two reward tokens
        _addReward(address(rewardToken1), REWARD_AMOUNT, REWARD_DURATION);
        _addReward(address(rewardToken2), REWARD_AMOUNT * 2, REWARD_DURATION);

        vm.startPrank(address(user1Actor));
        stakingToken.approve(address(staker), STAKE_AMOUNT);
        bytes memory stakeCallData = abi.encodeWithSelector(staker.stake.selector, STAKE_AMOUNT);
        user1Actor.proxy(address(staker), stakeCallData);
        vm.stopPrank();

        vm.warp(block.timestamp + REWARD_DURATION / 2);

        vm.prank(address(user1Actor));
        bytes memory claimAllCallData = abi.encodeWithSelector(staker.claimAllRewards.selector);
        user1Actor.proxy(address(staker), claimAllCallData);

        assertApproxEqRel(rewardToken1.balanceOf(address(user1Actor)), REWARD_AMOUNT / 2, 0.01e18);

        assertApproxEqRel(rewardToken2.balanceOf(address(user1Actor)), REWARD_AMOUNT * 2 / 2, 0.01e18);
    }

    // forge test --match-contract StakerTest --match-test testRewardDistributionMultipleUsers ✔️
    // Test reward distribution with multiple users
    function testRewardDistributionMultipleUsers() public {
        // Add reward
        _addReward(address(rewardToken1), REWARD_AMOUNT, REWARD_DURATION);

        vm.startPrank(address(user1Actor));
        stakingToken.approve(address(staker), STAKE_AMOUNT);
        bytes memory stakeCallData = abi.encodeWithSelector(staker.stake.selector, STAKE_AMOUNT);
        user1Actor.proxy(address(staker), stakeCallData);
        vm.stopPrank();

        vm.warp(block.timestamp + REWARD_DURATION / 4);

        vm.startPrank(address(user2Actor));
        stakingToken.approve(address(staker), STAKE_AMOUNT);
        user2Actor.proxy(address(staker), stakeCallData);
        vm.stopPrank();

        vm.warp(block.timestamp + (REWARD_DURATION * 3 / 4));

        // User1 should have earned 25% + (75% / 2) = 62.5% of rewards
        // User2 should have earned 75% / 2 = 37.5% of rewards
        uint256 user1Earned = staker.earned(address(user1Actor), address(rewardToken1));
        uint256 user2Earned = staker.earned(address(user2Actor), address(rewardToken1));

        uint256 expectedUser1 = REWARD_AMOUNT * 625 / 1000; // 62.5%
        uint256 expectedUser2 = REWARD_AMOUNT * 375 / 1000; // 37.5%

        assertApproxEqRel(user1Earned, expectedUser1, 0.01e18);
        assertApproxEqRel(user2Earned, expectedUser2, 0.01e18);

        // Both users claim rewards
        vm.prank(address(user1Actor));
        bytes memory claimCallData = abi.encodeWithSelector(staker.claimRewards.selector, address(rewardToken1));
        user1Actor.proxy(address(staker), claimCallData);

        vm.prank(address(user2Actor));
        user2Actor.proxy(address(staker), claimCallData);

        // Verify rewards were transferred correctly
        assertApproxEqRel(rewardToken1.balanceOf(address(user1Actor)), expectedUser1, 0.01e18);

        assertApproxEqRel(rewardToken1.balanceOf(address(user2Actor)), expectedUser2, 0.01e18);
    }

    // forge test --match-contract StakerTest --match-test test_RevertWhen_ZeroStake ❌
    //zero stake revert
    function test_RevertWhen_ZeroStake() public {
        vm.prank(address(user1Actor));
        bytes memory zeroStakeCallData = abi.encodeWithSelector(staker.stake.selector, 0);

        vm.expectRevert("Cannot stake 0");
        user1Actor.proxy(address(staker), zeroStakeCallData);
    }

    // forge test --match-contract StakerTest --match-test  test_RevertWhen_InsufficientBalance ❌
    // insufficient balance revert
    function test_RevertWhen_InsufficientBalance() public {
        vm.prank(address(user1Actor));
        bytes memory withdrawCallData = abi.encodeWithSelector(staker.withdraw.selector, STAKE_AMOUNT);

        vm.expectRevert("Insufficient balance");
        user1Actor.proxy(address(staker), withdrawCallData);
    }

    // forge test --match-contract StakerTest --match-test test_RevertWhen_InvalidRewardToken ❌
    //invalid reward token revert
    function test_RevertWhen_InvalidRewardToken() public {
        vm.prank(address(user1Actor));
        bytes memory claimCallData = abi.encodeWithSelector(staker.claimRewards.selector, address(rewardToken1));

        vm.expectRevert("Invalid reward token");
        user1Actor.proxy(address(staker), claimCallData);
    }

    // forge test --match-contract StakerTest --match-test test_RevertWhen_AddRewardNotAdmin ❌
    // add reward not admin revert
    function test_RevertWhen_AddRewardNotAdmin() public {
        vm.prank(address(user1Actor));
        bytes memory addRewardCallData =
            abi.encodeWithSelector(staker.addReward.selector, address(rewardToken1), REWARD_AMOUNT, REWARD_DURATION);

        vm.expectRevert(bytes("AccessControl: account"));
        user1Actor.proxy(address(staker), addRewardCallData);
    }

    //forge test --match-contract StakerTest --match-test test_RevertWhen_RemoveActiveReward ❌
    // removing active reward revert
    function test_RevertWhen_RemoveActiveReward() public {
        _addReward(address(rewardToken1), REWARD_AMOUNT, REWARD_DURATION);

        vm.prank(address(adminActor));
        bytes memory removeCallData = abi.encodeWithSelector(staker.removeRewardToken.selector, address(rewardToken1));

        vm.expectRevert("Reward ongoing");
        adminActor.proxy(address(staker), removeCallData);
    }

    //  forge test --match-contract StakerTest --match-test test_RevertWhen_AddRewardWithInvalidParameters ❌
    // Test for revert when adding reward with invalid parameters
    function test_RevertWhen_AddRewardWithInvalidParameters() public {
        vm.startPrank(address(adminActor));
        rewardToken1.approve(address(staker), REWARD_AMOUNT);

        bytes memory addRewardCallData = abi.encodeWithSelector(
            staker.addReward.selector,
            address(rewardToken1),
            REWARD_AMOUNT,
            0 // Zero duration
        );

        vm.expectRevert("Invalid parameters");
        adminActor.proxy(address(staker), addRewardCallData);
        vm.stopPrank();
    }

    // forge test --match-contract StakerTest --match-test test_RevertWhen_AddRewardNotDivisible ❌
    // Updated test case for add reward not divisible revert
    function test_RevertWhen_AddRewardNotDivisible() public {
        vm.startPrank(address(adminActor));
        rewardToken1.approve(address(staker), REWARD_AMOUNT);

        // Not divisible (REWARD_AMOUNT not divisible by REWARD_DURATION + 1)
        bytes memory addRewardCallData =
            abi.encodeWithSelector(staker.addReward.selector, address(rewardToken1), REWARD_AMOUNT, REWARD_DURATION + 1);

        vm.expectRevert("TotalRewards must be divisible by duration");
        adminActor.proxy(address(staker), addRewardCallData);
        vm.stopPrank();
    }

    // forge test --match-contract StakerTest --match-test testNoLeftoverRewards ❌
    // Test to verify there's no leftover reward tokens after claiming
    function testNoLeftoverRewards() public {
        // Add reward
        _addReward(address(rewardToken1), REWARD_AMOUNT, REWARD_DURATION);

        // User stakes tokens
        vm.startPrank(address(user1Actor));
        stakingToken.approve(address(staker), STAKE_AMOUNT);
        bytes memory stakeCallData = abi.encodeWithSelector(staker.stake.selector, STAKE_AMOUNT);
        user1Actor.proxy(address(staker), stakeCallData);
        vm.stopPrank();

        // Advance through the entire reward period
        vm.warp(block.timestamp + REWARD_DURATION + 1);

        // Claim rewards
        vm.prank(address(user1Actor));
        bytes memory claimCallData = abi.encodeWithSelector(staker.claimRewards.selector, address(rewardToken1));
        user1Actor.proxy(address(staker), claimCallData);

        // User should have received all rewards
        assertEq(rewardToken1.balanceOf(address(user1Actor)), REWARD_AMOUNT);

        // Check that user has no more rewards to claim
        uint256 remainingRewards = staker.earned(address(user1Actor), address(rewardToken1));
        assertEq(remainingRewards, 0);
    }

    // forge test --match-contract StakerTest --match-test testRewardUpdateOnNewToken ❌
    // Test for proper updating of rewards when a new reward token is added
    function testRewardUpdateOnNewToken() public {
        // User stakes tokens first
        vm.startPrank(address(user1Actor));
        stakingToken.approve(address(staker), STAKE_AMOUNT);
        bytes memory stakeCallData = abi.encodeWithSelector(staker.stake.selector, STAKE_AMOUNT);
        user1Actor.proxy(address(staker), stakeCallData);
        vm.stopPrank();

        // Add first reward token
        _addReward(address(rewardToken1), REWARD_AMOUNT, REWARD_DURATION);

        // Advance some time
        vm.warp(block.timestamp + REWARD_DURATION / 2);

        // Add second reward token
        _addReward(address(rewardToken2), REWARD_AMOUNT * 2, REWARD_DURATION);

        // Complete the duration
        vm.warp(block.timestamp + REWARD_DURATION);

        // Claim all rewards
        vm.prank(address(user1Actor));
        bytes memory claimAllCallData = abi.encodeWithSelector(staker.claimAllRewards.selector);
        user1Actor.proxy(address(staker), claimAllCallData);
        // Verify both rewards were received
        uint256 reward1 = rewardToken1.balanceOf(address(user1Actor));
        uint256 reward2 = rewardToken2.balanceOf(address(user1Actor));

        // First token should be fully distributed
        assertApproxEqRel(reward1, REWARD_AMOUNT, 0.01e18);

        // Second token should be fully distributed too
        assertApproxEqRel(reward2, REWARD_AMOUNT * 2, 0.01e18);
    }
}
