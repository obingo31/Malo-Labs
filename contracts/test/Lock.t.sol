// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "./mocks/MockERC20.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract LockTestlock is Test {
    Staking public staking;
    MockERC20 public stakingToken;
    MockERC20 public rewardToken;
    // Use a test address for the user
    address public user = address(0x1);
    // We'll use the test contract itself as the lock manager (it has LOCK_MANAGER_ROLE via constructor)
    address public lockManager = address(this);
    uint256 public constant INITIAL_STAKE = 100e18;

    // Event signature for LockAmountChanged (must match the staking contract)
    event LockAmountChanged(address indexed user, address indexed lockManager, uint256 newAmount);

    function setUp() public {
        // Deploy separate tokens for staking and rewards
        stakingToken = new MockERC20("Staking Token", "STK");
        rewardToken = new MockERC20("Reward Token", "RWD");

        // Deploy the staking contract; initialOwner (and thus lockManager) is address(this)
        staking = new Staking(address(stakingToken), address(rewardToken), address(this), 7 days, address(0xFee));
        // Mint and stake tokens for user
        stakingToken.mint(user, INITIAL_STAKE);
        vm.prank(user);
        stakingToken.approve(address(staking), INITIAL_STAKE);
        vm.prank(user);
        staking.stake(INITIAL_STAKE);
    }

    // Test 1: When the lock amount is zero, it should revert with ZeroAmount.
    function test_WhenAmountIsZero() public {
        vm.expectRevert(Errors.ZeroAmount.selector);
        staking.lock(user, 0);
    }

    // Test 2: When the user has insufficient unlocked balance, it should revert with InsufficientBalance.
    function test_WhenUserHasInsufficientUnlockedBalance() public {
        // First, have the user allow this lock manager an allowance.
        vm.prank(user);
        staking.allowManager(lockManager, 200e18, "");
        // The user only staked 100e18, so trying to lock 150e18 should revert.
        vm.expectRevert(Errors.InsufficientBalance.selector);
        staking.lock(user, 150e18);
    }

    // Test 3: When the lock manager has no existing allowance, it should revert with LockDoesNotExist.
    function test_WhenLockManagerHasNoExistingAllowance() public {
        // Without calling allowManager, attempt to lock a nonzero amount.
        vm.expectRevert(Errors.LockDoesNotExist.selector);
        staking.lock(user, 50e18);
    }

    // Test 4: When the new lock amount exceeds the allowance, it should revert with InsufficientAllowance.
    function test_WhenNewAmountExceedsAllowance() public {
        // Allow the lock manager an allowance of 50e18.
        vm.prank(user);
        staking.allowManager(lockManager, 50e18, "");
        // Now trying to lock 60e18 should revert.
        vm.expectRevert(Errors.InsufficientAllowance.selector);
        staking.lock(user, 60e18);
    }

    // Test 5: When valid parameters are provided, it should increase the locked amount and emit LockAmountChanged.
    function test_WhenValidParameters() public {
        uint256 allowance = 100e18;
        vm.prank(user);
        staking.allowManager(lockManager, allowance, "");

        // Expect the LockAmountChanged event with the new locked amount equal to 50e18.
        vm.expectEmit(true, false, false, false);
        emit LockAmountChanged(user, lockManager, 50e18);

        // Lock 50 tokens successfully.
        staking.lock(user, 50e18);

        // Verify that the locked amount is updated correctly.
        (uint256 lockedAmount, uint256 currentAllowance) = staking.getLock(user, lockManager);
        assertEq(lockedAmount, 50e18, "Locked amount not updated correctly");
        // The allowance remains unchanged.
        assertEq(currentAllowance, allowance, "Allowance should remain unchanged");
    }
}
