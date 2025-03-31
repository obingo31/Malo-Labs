// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./mocks/MockERC20.sol";
import "../src/Staking.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract RewardsTest is Test {
    Staking public staking;
    MockERC20 public maloToken;
    MockERC20 public stakingToken;
    address public feeRecipient = address(0xFee);
    address public user = address(0x1);
    uint256 public constant REWARD_PERIOD = 7 days;

    function setUp() public {
        stakingToken = new MockERC20("Staking Token", "STK");
        maloToken = new MockERC20("Reward Token", "MALO");

        staking = new Staking(
            address(stakingToken),
            address(maloToken),
            address(this), // rewardsDistribution
            REWARD_PERIOD,
            feeRecipient
        );
    }

    modifier whenPartialRewardPeriodPassed() {
        _fundAndNotifyRewards(1000e18);
        vm.warp(block.timestamp + REWARD_PERIOD / 2);
        _;
    }

    modifier whenProtocolFeeIs5Percent() {
        _setProtocolFee(50);
        _;
    }

    modifier whenNoRewardsAccumulated() {
        _;
    }

    function test_RevertWhen_NoRewardsAccumulated() external whenNoRewardsAccumulated {
        vm.expectRevert(Errors.NoRewardsAvailable.selector);
        staking.claimRewards();
    }

    function test_ShouldDeductCorrectFee() external whenProtocolFeeIs5Percent {
        // 1. Setup rewards
        _fundAndNotifyRewards(100e18);

        // 2. Stake tokens
        _stakeTokens(user, 100e18);

        // 3. Warp full reward period
        vm.warp(block.timestamp + REWARD_PERIOD);

        // 4. Calculate expected fee (5% of 100e18)
        uint256 expectedFee = 5e18;
        uint256 expectedNet = 95e18;

        // 5. Verify balances before
        uint256 initialRecipient = maloToken.balanceOf(feeRecipient);
        uint256 initialUser = maloToken.balanceOf(user);

        // 6. Claim rewards
        vm.prank(user);
        staking.claimRewards();

        // 7. Verify balances after
        assertEq(maloToken.balanceOf(feeRecipient), initialRecipient + expectedFee, "Fee not sent");
        assertEq(maloToken.balanceOf(user), initialUser + expectedNet, "Net reward mismatch");
    }

    function test_ShouldCalculateProratedRewards() external {
        // 1. Stake first
        _stakeTokens(user, 100e18);

        // 2. Fund rewards and start distribution
        _fundAndNotifyRewards(1000e18);

        // 3. Warp half the reward period
        vm.warp(block.timestamp + REWARD_PERIOD / 2);

        // 4. Calculate expected rewards (50% of total)
        uint256 expectedReward = 500e18; // 1000e18 * 0.5

        // 5. Claim and verify
        vm.prank(user);
        staking.claimRewards();

        assertEq(maloToken.balanceOf(user), expectedReward, "Prorated rewards incorrect");
    }

    function _fundAndNotifyRewards(uint256 amount) private {
        maloToken.mint(address(staking), amount);
        vm.prank(address(this));
        staking.notifyRewardAmount(amount);
    }

    function _stakeTokens(address account, uint256 amount) private {
        stakingToken.mint(account, amount);
        vm.prank(account);
        stakingToken.approve(address(staking), amount);
        vm.prank(account);
        staking.stake(amount);
    }

    function _setProtocolFee(uint256 fee) private {
        vm.prank(address(this)); // Test contract is admin
        staking.setProtocolFee(fee);
    }
}
