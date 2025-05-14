// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MALGovernanceStaking} from "src/MALGovernanceStaking.sol";
import {Setup} from "./Setup.sol";

abstract contract BeforeAfter is Setup {
    struct Proposal {
        address target;
        bytes data;
        address proposer;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool expired;
    }

    enum OpType {
        GENERIC,
        STAKE,
        WITHDRAW,
        CREATE_PROPOSAL,
        VOTE,
        EXECUTE_PROPOSAL,
        CLAIM_REWARDS,
        UPDATE_VOTING_PERIOD,
        UPDATE_QUORUM,
        SET_COOLDOWN,
        CLEAN_PROPOSALS,
        PAUSE
    }

    struct Vars {
        uint256 totalStaked;
        uint256 proposalCount;
        uint256 votingPeriod;
        uint256 quorumPercentage;
        uint256 withdrawalCooldown;
        uint256 rewardRate;
        uint256 lastStakeTime;
        uint256 governanceTokenBalance;
        uint256 utilityTokenBalance;
        bool paused;
        mapping(address => uint256) userStakes;
        mapping(address => uint256) userRewards;
        mapping(uint256 => Proposal) proposals;
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
        MALGovernanceStaking staking = malGovernanceStaking;
        address currentActor = _currentActor();
        IERC20 govToken = IERC20(_getAssetAddress(0));
        IERC20 utilToken = IERC20(_getAssetAddress(1));

        _before.totalStaked = staking.totalStaked();
        _before.proposalCount = staking.proposalCount();
        _before.votingPeriod = staking.votingPeriod();
        _before.quorumPercentage = staking.quorumPercentage();
        _before.withdrawalCooldown = staking.withdrawalCooldown();
        _before.rewardRate = staking.rewardRate();
        _before.paused = staking.paused();
        _before.userStakes[currentActor] = staking.stakedBalance(currentActor);
        _before.sig = msg.sig;
        _before.governanceTokenBalance = govToken.balanceOf(address(staking));
        _before.utilityTokenBalance = utilToken.balanceOf(address(staking));

        if (_before.proposalCount > 0) {
            (
                address target,
                bytes memory data,
                address proposer,
                uint256 forVotes,
                uint256 againstVotes,
                uint256 startTime,
                uint256 endTime,
                bool executed,
                bool expired
            ) = staking.proposals(_before.proposalCount);

            _before.proposals[_before.proposalCount] =
                Proposal(target, data, proposer, forVotes, againstVotes, startTime, endTime, executed, expired);
        }
    }

    function __after() internal {
        MALGovernanceStaking staking = malGovernanceStaking;
        address currentActor = _currentActor();
        IERC20 govToken = IERC20(_getAssetAddress(0));
        IERC20 utilToken = IERC20(_getAssetAddress(1));

        _after.totalStaked = staking.totalStaked();
        _after.proposalCount = staking.proposalCount();
        _after.votingPeriod = staking.votingPeriod();
        _after.quorumPercentage = staking.quorumPercentage();
        _after.withdrawalCooldown = staking.withdrawalCooldown();
        _after.rewardRate = staking.rewardRate();
        _after.paused = staking.paused();
        _after.userStakes[currentActor] = staking.stakedBalance(currentActor);
        _after.sig = msg.sig;
        _after.governanceTokenBalance = govToken.balanceOf(address(staking));
        _after.utilityTokenBalance = utilToken.balanceOf(address(staking));

        if (_after.proposalCount > 0) {
            (
                address target,
                bytes memory data,
                address proposer,
                uint256 forVotes,
                uint256 againstVotes,
                uint256 startTime,
                uint256 endTime,
                bool executed,
                bool expired
            ) = staking.proposals(_after.proposalCount);

            _after.proposals[_after.proposalCount] =
                Proposal(target, data, proposer, forVotes, againstVotes, startTime, endTime, executed, expired);
        }
    }
}
