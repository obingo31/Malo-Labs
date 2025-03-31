// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
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

contract SlashTest is Test {
    Staking public staking;
    MockERC20 public stakingToken;
    MockLockManager public lockManager;

    address public fromUser = address(0x1);
    address public toUser = address(0x2);
    address public unauthorized = address(0x3);
    uint256 public constant STAKE_AMOUNT = 100e18;
    uint256 public constant LOCK_AMOUNT = 50e18;

    event LockAmountChanged(address indexed user, address indexed lockManager, uint256 newAmount);
    event StakeTransferred(address indexed from, address indexed to, uint256 amount);

    function setUp() public {
        stakingToken = new MockERC20("Staking Token", "STK");
        address maloToken = address(new MockERC20("Reward Token", "MALO"));
        lockManager = new MockLockManager();

        staking = new Staking(address(stakingToken), maloToken, address(this), 7 days, address(0xFee));

        // Setup roles and initial lock
        staking.grantRole(staking.LOCK_MANAGER_ROLE(), address(lockManager));
        _stakeAndLock(fromUser, STAKE_AMOUNT, LOCK_AMOUNT);
    }

    function test_GivenAmountIsZero() external {
        vm.expectRevert(Errors.ZeroAmount.selector);
        vm.prank(address(lockManager));
        staking.slash(fromUser, toUser, 0);
    }

    function test_WhenCallerIsUnauthorized() external {
        bytes32 role = staking.LOCK_MANAGER_ROLE();

        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")), unauthorized, role
            )
        );

        vm.prank(unauthorized);
        staking.slash(fromUser, toUser, LOCK_AMOUNT);
    }

    function test_WhenLockedAmountIsInsufficient() external {
        uint256 excessAmount = LOCK_AMOUNT + 1e18;
        vm.expectRevert(Errors.InsufficientLock.selector);
        vm.prank(address(lockManager));
        staking.slash(fromUser, toUser, excessAmount);
    }

    function test_WhenValidParameters() external {
        uint256 slashAmount = LOCK_AMOUNT / 2;

        // Expected events
        vm.expectEmit(true, true, true, true);
        emit LockAmountChanged(fromUser, address(lockManager), LOCK_AMOUNT - slashAmount);
        vm.expectEmit(true, true, true, true);
        emit StakeTransferred(fromUser, toUser, slashAmount);

        // Get initial balances
        uint256 initialFromBalance = staking.balanceOf(fromUser);
        uint256 initialToBalance = staking.balanceOf(toUser);

        // Execute slash
        vm.prank(address(lockManager));
        staking.slash(fromUser, toUser, slashAmount);

        // Verify locked amount
        (uint256 currentLockAmount,) = staking.getLock(fromUser, address(lockManager));
        assertEq(currentLockAmount, LOCK_AMOUNT - slashAmount, "Lock amount mismatch");

        // Verify balances
        assertEq(staking.balanceOf(fromUser), initialFromBalance - slashAmount, "From balance mismatch");
        assertEq(staking.balanceOf(toUser), initialToBalance + slashAmount, "To balance mismatch");
        assertEq(staking.totalStaked(), STAKE_AMOUNT, "Total staked should remain constant");
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
