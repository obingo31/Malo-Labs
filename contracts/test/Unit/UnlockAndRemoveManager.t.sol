// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/Staking.sol";
import "src/interfaces/ILockManager.sol";
import {Errors} from "src/libraries/Errors.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract MockLockManager is ILockManager {
    function canUnlock(address, uint256) external pure override returns (bool) {
        return true;
    }
}

//  forge test --match-contract UnlockAndRemoveManagerTest --match-test test_WhenCalledByUser --fork-url $FORK_URL --fork-block-number $FORK_BLOCK_NUMBER
//  forge test --match-contract UnlockAndRemoveManagerTest --match-test test_WhenCalledByLockManager --fork-url $FORK_URL --fork-block-number $FORK_BLOCK_NUMBER
//  forge test --match-contract UnlockAndRemoveManagerTest --match-test test_WhenCallerIsUnauthorized --fork-url $FORK_URL --fork-block-number $FORK_BLOCK_NUMBER
//  forge test --match-contract UnlockAndRemoveManagerTest --match-test test_GivenLockDoesNotExist --fork-url $FORK_URL --fork-block-number $FORK_BLOCK_NUMBER
//  forge test --match-contract UnlockAndRemoveManagerTest --match-test test_WhenCalledByUser --fork-url $FORK_URL --fork-block-number $FORK_BLOCK_NUMBER --gas-report

contract UnlockAndRemoveManagerTest is Test {
    Staking public staking;
    MockERC20 public stakingToken;
    MockLockManager public lockManager;

    address public user = address(0x1);
    address public unauthorized = address(0x3);
    uint256 public constant STAKE_AMOUNT = 100e18;
    uint256 public constant LOCK_AMOUNT = 50e18;

    event LockAmountChanged(address indexed user, address indexed lockManager, uint256 newAmount);
    event LockManagerRemoved(address indexed user, address indexed lockManager);

    function setUp() public {
        stakingToken = new MockERC20("Staking Token", "STK");
        address maloToken = address(new MockERC20("Reward Token", "MALO"));
        lockManager = new MockLockManager();

        staking = new Staking(address(stakingToken), maloToken, address(this), 7 days, address(0xFee));

        // Setup roles and initial lock
        staking.grantRole(staking.LOCK_MANAGER_ROLE(), address(lockManager));
        _stakeAndLock(user, STAKE_AMOUNT, LOCK_AMOUNT);
    }

    function test_GivenLockDoesNotExist() external {
        address nonExistentManager = address(0xDEAD);
        vm.expectRevert(Errors.CannotUnlock.selector);
        vm.prank(user);
        staking.unlockAndRemoveManager(user, nonExistentManager);
    }

    function test_WhenCallerIsUnauthorized() external {
        vm.expectRevert(Errors.CannotUnlock.selector);
        vm.prank(unauthorized);
        staking.unlockAndRemoveManager(user, address(lockManager));
    }

    function test_WhenCalledByUser() external {
        // Verify initial state
        (uint256 initialAmount,) = staking.getLock(user, address(lockManager));
        assertEq(initialAmount, LOCK_AMOUNT, "Initial lock amount mismatch");
        assertEq(staking.lockedBalanceOf(user), LOCK_AMOUNT, "Initial locked balance mismatch");

        // Expect events
        vm.expectEmit(true, true, true, true);
        emit LockAmountChanged(user, address(lockManager), 0);
        vm.expectEmit(true, true, true, true);
        emit LockManagerRemoved(user, address(lockManager));

        // Execute
        vm.prank(user);
        staking.unlockAndRemoveManager(user, address(lockManager));

        // Verify post-state
        (uint256 finalAmount,) = staking.getLock(user, address(lockManager));
        assertEq(finalAmount, 0, "Lock amount not cleared");
        assertEq(staking.lockedBalanceOf(user), 0, "Total locked not updated");
    }

    function test_WhenCalledByLockManager() external {
        // Verify initial state
        (uint256 initialAmount,) = staking.getLock(user, address(lockManager));
        assertEq(initialAmount, LOCK_AMOUNT, "Initial lock amount mismatch");

        // Expect events
        vm.expectEmit(true, true, true, true);
        emit LockAmountChanged(user, address(lockManager), 0);
        vm.expectEmit(true, true, true, true);
        emit LockManagerRemoved(user, address(lockManager));

        // Execute
        vm.prank(address(lockManager));
        staking.unlockAndRemoveManager(user, address(lockManager));

        // Verify post-state
        (uint256 finalAmount,) = staking.getLock(user, address(lockManager));
        assertEq(finalAmount, 0, "Lock amount not cleared");
        assertFalse(_lockManagerExists(user, address(lockManager)), "Lock manager not removed");
    }

    function _stakeAndLock(address account, uint256 stakeAmount, uint256 lockAmount) private {
        // Stake tokens
        stakingToken.mint(account, stakeAmount);
        vm.startPrank(account);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        staking.allowManager(address(lockManager), lockAmount, "");
        vm.stopPrank();

        // Create lock
        vm.prank(address(lockManager));
        staking.lock(account, lockAmount);
    }

    function _lockManagerExists(address user_, address manager_) private view returns (bool) {
        (uint256 amount,) = staking.getLock(user_, manager_);
        return amount > 0;
    }
}
