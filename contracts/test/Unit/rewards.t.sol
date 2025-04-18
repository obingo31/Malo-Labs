// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../mocks/MockERC20.sol";
import "src/Staking.sol";
import {Errors} from "src/libraries/Errors.sol";

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

        staking = new Staking(address(stakingToken), address(maloToken), address(this), REWARD_PERIOD, feeRecipient);
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

    function _fundAndNotifyRewards(
        uint256 amount
    ) private {
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

    function _setProtocolFee(
        uint256 fee
    ) private {
        vm.prank(address(this));
        staking.setProtocolFee(fee);
    }
}
