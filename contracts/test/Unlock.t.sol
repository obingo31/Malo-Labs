// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "../src/interfaces/ILockManager.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract MockLockManager is ILockManager {
    function canUnlock(address, uint256) external pure override returns (bool) {
        return true;
    }
}

contract UnlockTest is Test {
    Staking public staking;
    MockERC20 public stakingToken;
    MockLockManager public lockManager;

    address public user = address(0x1);
    address public unauthorized = address(0x3);
    uint256 public constant STAKE_AMOUNT = 100e18;
    uint256 public constant LOCK_AMOUNT = 50e18;

    event LockAmountChanged(address indexed user, address indexed lockManager, uint256 newAmount);

    function setUp() public {
        stakingToken = new MockERC20("Staking Token", "STK");
        address maloToken = address(new MockERC20("Reward Token", "MALO"));
        lockManager = new MockLockManager();

        staking = new Staking(
            address(stakingToken),
            maloToken,
            address(this), // initialOwner
            7 days,
            address(0xFee)
        );

        // Setup roles
        staking.grantRole(staking.LOCK_MANAGER_ROLE(), address(lockManager));

        // Initial stake and lock
        _stakeAndLock(user, STAKE_AMOUNT, LOCK_AMOUNT);
    }

    function test_GivenAmountIsZero() external {
        vm.expectRevert(Errors.ZeroAmount.selector);
        vm.prank(user);
        staking.unlock(user, address(lockManager), 0);
    }

    function test_WhenCallerIsUnauthorized() external {
        vm.expectRevert(Errors.CannotUnlock.selector);
        vm.prank(unauthorized);
        staking.unlock(user, address(lockManager), LOCK_AMOUNT);
    }

    function test_WhenLockedAmountIsInsufficient() external {
        vm.expectRevert(Errors.CannotUnlock.selector);
        vm.prank(user);
        staking.unlock(user, address(lockManager), LOCK_AMOUNT + 1);
    }

    function test_WhenCalledByUserWithValidParameters() external {
        uint256 unlockAmount = LOCK_AMOUNT / 2;

        vm.expectEmit(true, true, true, true);
        emit LockAmountChanged(user, address(lockManager), LOCK_AMOUNT - unlockAmount);

        vm.prank(user);
        staking.unlock(user, address(lockManager), unlockAmount);

        (uint256 currentLockAmount,) = staking.getLock(user, address(lockManager));
        assertEq(currentLockAmount, LOCK_AMOUNT - unlockAmount, "Lock amount mismatch");
        assertEq(staking.lockedBalanceOf(user), LOCK_AMOUNT - unlockAmount, "Total locked mismatch");
    }

    function test_WhenCalledByLockManagerWithValidParameters() external {
        uint256 unlockAmount = LOCK_AMOUNT / 2;

        vm.expectEmit(true, true, true, true);
        emit LockAmountChanged(user, address(lockManager), LOCK_AMOUNT - unlockAmount);

        vm.prank(address(lockManager));
        staking.unlock(user, address(lockManager), unlockAmount);

        (uint256 currentLockAmount,) = staking.getLock(user, address(lockManager));
        assertEq(currentLockAmount, LOCK_AMOUNT - unlockAmount, "Lock amount mismatch");
        assertEq(staking.lockedBalanceOf(user), LOCK_AMOUNT - unlockAmount, "Total locked mismatch");
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
}
