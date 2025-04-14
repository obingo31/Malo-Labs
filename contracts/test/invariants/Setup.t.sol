// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {Actor} from "./Actor.sol";
import {Staker} from "src/Staker.sol";
import {IStaker} from "src/interfaces/IStaker.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Setup {
    using Strings for uint256;

    struct NamedActor {
        address account;
        Actor proxy;
        uint256 index;
    }

    Staker public staker;
    ERC20Mock public stakingToken;
    ERC20Mock[] public rewardTokens;

    NamedActor[] public actors;
    uint256 public constant INITIAL_STAKE_BALANCE = 1e24;
    uint256 public constant REWARD_AMOUNT = 1e24;
    address public immutable admin = address(this);
    address public constant PAUSE_GUARDIAN = address(0xdead);

    constructor() {
        _deployCore();
        _setupActors();
        _initializeActorBalances();
    }

    function _deployCore() internal {
        stakingToken = new ERC20Mock("Staking Token", "STK");
        staker = new Staker(address(stakingToken), admin, PAUSE_GUARDIAN);

        for (uint256 i = 0; i < 3; i++) {
            ERC20Mock rewardToken = new ERC20Mock(
                string(abi.encodePacked("Reward ", i.toString())), string(abi.encodePacked("RWD", i.toString()))
            );
            rewardToken.mint(address(this), REWARD_AMOUNT);
            rewardToken.approve(address(staker), type(uint256).max);
            rewardTokens.push(rewardToken);
            staker.addReward(address(rewardToken), REWARD_AMOUNT, 1 weeks);
        }
    }

    function _setupActors() internal {
        string[6] memory names = ["shika", "noko", "nokonoko", "koshi", "tantan", "mochi"];
        address[] memory tokens = new address[](1);
        tokens[0] = address(stakingToken);
        address[] memory contracts = new address[](1);
        contracts[0] = address(staker);

        for (uint256 i = 0; i < names.length; i++) {
            address account = address(uint160(uint256(keccak256(abi.encode(names[i])))));
            Actor proxy = new Actor(tokens, contracts);
            actors.push(NamedActor(account, proxy, i));
        }
    }

    function _initializeActorBalances() internal {
        for (uint256 i = 0; i < actors.length; i++) {
            stakingToken.mint(address(actors[i].proxy), INITIAL_STAKE_BALANCE);
            actors[i].proxy.approveToken(address(stakingToken), address(staker), type(uint256).max);
        }
    }

    // Echidna properties
    function echidna_total_staked() public view virtual returns (bool) {
        uint256 total;
        for (uint256 i = 0; i < actors.length; i++) {
            total += staker.stakedBalanceOf(address(actors[i].proxy));
        }
        return staker.totalStaked() == total;
    }

    // function echidna_reward_integrity() public view returns (bool) {
    //     for (uint256 i = 0; i < rewardTokens.length; i++) {
    //         IStaker.Reward memory r = staker.rewards(address(rewardTokens[i]));
    //         uint256 contractBalance = rewardTokens[i].balanceOf(address(staker));

    //         uint256 maxPossible = r.rate * r.duration;
    //         uint256 elapsed = block.timestamp - r.lastUpdateTime;
    //         uint256 distributed = elapsed > r.duration ? maxPossible : r.rate * elapsed;

    //         if (contractBalance < (REWARD_AMOUNT - distributed)) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    function echidna_role_permissions() public view virtual returns (bool) {
        return staker.hasRole(staker.DEFAULT_ADMIN_ROLE(), admin) && staker.hasRole(staker.REWARDS_ADMIN_ROLE(), admin)
            && staker.hasRole(staker.PAUSE_GUARDIAN_ROLE(), PAUSE_GUARDIAN);
    }
}
