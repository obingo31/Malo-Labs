// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {StakingToken} from "../../src/StakingToken.sol";
import {MALGovernanceStaking} from "../../src/MALGovernanceStaking.sol";

contract WithdrawTest is Test {
    StakingToken public stakingToken;
    StakingToken public utilityToken;
    MALGovernanceStaking public malGovernanceStaking;
    address public owner;
    address public daoMultisig;
    address public user;
    uint256 public constant STAKE_AMOUNT = 100e18;
    uint256 public constant COOLDOWN_PERIOD = 7 days;

    function setUp() public {
        owner = makeAddr("owner");
        daoMultisig = makeAddr("daoMultisig");
        user = makeAddr("user");

        vm.startPrank(owner);

        stakingToken = new StakingToken("Governance", "GOV", owner);
        utilityToken = new StakingToken("Utility", "UTIL", owner);

        malGovernanceStaking = new MALGovernanceStaking(address(stakingToken), address(utilityToken), daoMultisig);

        stakingToken.mint(user, STAKE_AMOUNT);

        vm.stopPrank();
    }

    function test_RevertWhen_InsufficientBalance() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        malGovernanceStaking.withdraw(STAKE_AMOUNT);
        vm.stopPrank();
    }

    function test_RevertWhen_CooldownActive() public {
        vm.startPrank(user);
        stakingToken.approve(address(malGovernanceStaking), STAKE_AMOUNT);
        malGovernanceStaking.stake(STAKE_AMOUNT);

        // withdraw before cooldown expires
        vm.expectRevert(abi.encodeWithSignature("CooldownActive()"));
        malGovernanceStaking.withdraw(STAKE_AMOUNT);
        vm.stopPrank();
    }

    function test_WithdrawFull_UpdatesDelegation() public {
        vm.startPrank(user);

        stakingToken.approve(address(malGovernanceStaking), STAKE_AMOUNT);
        malGovernanceStaking.stake(STAKE_AMOUNT);

        assertEq(stakingToken.delegates(address(malGovernanceStaking)), user);

        vm.warp(block.timestamp + COOLDOWN_PERIOD);

        malGovernanceStaking.withdraw(STAKE_AMOUNT);

        assertEq(malGovernanceStaking.stakedBalance(user), 0);
        assertEq(stakingToken.delegates(address(malGovernanceStaking)), address(0));

        vm.stopPrank();
    }

    function test_WithdrawPartial_NoUpdateDelegation() public {
        vm.startPrank(user);
        stakingToken.approve(address(malGovernanceStaking), STAKE_AMOUNT);
        malGovernanceStaking.stake(STAKE_AMOUNT);

        // Wait for cooldown to expire
        vm.warp(block.timestamp + COOLDOWN_PERIOD);

        uint256 withdrawAmount = STAKE_AMOUNT / 2;
        malGovernanceStaking.withdraw(withdrawAmount);
        assertEq(malGovernanceStaking.stakedBalance(user), STAKE_AMOUNT - withdrawAmount);
        vm.stopPrank();
    }

    function test_WithdrawExactlyAtCooldownExpiry() public {
        vm.startPrank(user);
        stakingToken.approve(address(malGovernanceStaking), STAKE_AMOUNT);
        malGovernanceStaking.stake(STAKE_AMOUNT);

        vm.warp(block.timestamp + COOLDOWN_PERIOD);

        malGovernanceStaking.withdraw(STAKE_AMOUNT);
        assertEq(malGovernanceStaking.stakedBalance(user), 0);
        vm.stopPrank();
    }

    function test_WithdrawZero_WithZeroBalance() public {
        vm.startPrank(user);

        // First stake some tokens
        stakingToken.approve(address(malGovernanceStaking), STAKE_AMOUNT);
        malGovernanceStaking.stake(STAKE_AMOUNT);

        // Wait for cooldown to expire
        vm.warp(block.timestamp + COOLDOWN_PERIOD);

        // Withdraw full amount first
        malGovernanceStaking.withdraw(STAKE_AMOUNT);

        // Now try withdrawing zero with zero balance
        malGovernanceStaking.withdraw(0);

        // Verify balance remains zero
        assertEq(malGovernanceStaking.stakedBalance(user), 0);

        vm.stopPrank();
    }
}
