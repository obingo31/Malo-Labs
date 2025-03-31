// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import "forge-std/console2.sol";
import {Setup} from "./Setup.sol";

abstract contract BeforeAfter is Setup {
    enum OpType {
        GENERIC,
        STAKE,
        UNSTAKE,
        CLAIM_REWARDS,
        EMERGENCY_WITHDRAW,
        SET_REWARD_RATE,
        SET_PROTOCOL_FEE,
        SET_FEE_RECIPIENT
    }

    struct Vars {
        uint256 totalStaked;
        uint256 totalRewardsDistributed;
        uint256 lastUpdateTime;
        uint256 periodFinish;
        uint256 protocolFee;
        address feeRecipient;
        uint256 feeRecipientBalance;
        uint256 stakingTokenBalance;
        uint256 rewardTokenBalance;
        bool paused;
        mapping(address => uint256) userStakes;
        mapping(address => uint256) userRewards;
        bytes4 sig;
    }

    Vars internal _before;
    Vars internal _after;
    OpType internal currentOperation;

    modifier updateGhosts() {
        currentOperation = OpType.GENERIC;
        __before();
        _;
        __after();
    }

    function __before() internal {
        _before.totalStaked = staking.totalStaked();
        _before.totalRewardsDistributed = staking.totalRewardsDistributed();
        _before.lastUpdateTime = staking.lastUpdateTime();
        _before.periodFinish = staking.periodFinish();
        _before.protocolFee = staking.protocolFee();
        _before.feeRecipient = staking.feeRecipient();
        _before.stakingTokenBalance = staking.stakingToken().balanceOf(address(staking));
        _before.paused = staking.paused();
        _before.sig = msg.sig;
    }

    function __after() internal {
        _after.totalStaked = staking.totalStaked();
        _after.totalRewardsDistributed = staking.totalRewardsDistributed();
        _after.lastUpdateTime = staking.lastUpdateTime();
        _after.periodFinish = staking.periodFinish();
        _after.protocolFee = staking.protocolFee();
        _after.feeRecipient = staking.feeRecipient();
        _after.stakingTokenBalance = staking.stakingToken().balanceOf(address(staking));
        _after.paused = staking.paused();
        _after.sig = msg.sig;
    }
}
