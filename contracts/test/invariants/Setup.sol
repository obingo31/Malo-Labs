// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {IHevm} from "@chimera/Hevm.sol";
import {Staking} from "src/Staking.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {Constants} from "src/Constants.sol";

abstract contract Setup is BaseSetup, Constants {
    IHevm internal immutable hevm = IHevm(HEVM_ADDRESS);
    
    // Core protocol contracts
    Staking public staking;
    ERC20Mock public stakingToken;
    ERC20Mock public rewardToken;

    // Ghost state tracking
    struct GhostState {
        uint256 totalStaked;
        mapping(address => uint256) userStaked;
        mapping(address => uint256) userRewards;
        uint256 protocolFees;
    }
    
    GhostState internal ghost;

    // Test actors
    address[] public actors;
    address public constant ADMIN = ALICE;
    address public constant FEE_RECEIVER = BOB;

    // Initial parameters (using Constants)
    uint256 public constant INITIAL_USER_BALANCE = INITIAL_BALANCE;
    uint256 public constant INITIAL_REWARD_POOL = WHALE_ALLOCATION;

    function generateActor(uint256 index) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked("actor", index)))));
    }

    function setUp() public virtual override {
        _deployContracts();
        _setupActors();
        _fundAccounts();
        _setupApprovals();
    }

    function _deployContracts() internal {
        stakingToken = new ERC20Mock("Staking Token", "STK");
        rewardToken = new ERC20Mock("Reward Token", "RWD");
        
        staking = new Staking(
            address(stakingToken),
            address(rewardToken),
            ADMIN,
            REWARD_EPOCH,
            FEE_RECEIVER
        );

        rewardToken.mint(address(staking), INITIAL_REWARD_POOL);
    }

    function _setupActors() internal {
        for (uint256 i = 1; i <= 3; i++) {
            address actor = generateActor(i);
            actors.push(actor);
            hevm.deal(actor, 1e18); // Give each actor 1 ether
        }
    }

    function _fundAccounts() internal {
        for (uint256 i = 0; i < actors.length; i++) {
            stakingToken.mint(actors[i], INITIAL_USER_BALANCE);
        }
    }

    function _setupApprovals() internal {
        for (uint256 i = 0; i < actors.length; i++) {
            hevm.prank(actors[i]);
            stakingToken.approve(address(staking), MAX_UINT);
        }
    }

    // Ghost state management
    function _updateGhostState(address user) internal {
        ghost.totalStaked = staking.totalStaked();
        ghost.userStaked[user] = staking.balanceOf(user);
        ghost.userRewards[user] = staking.earned(user);
        ghost.protocolFees = rewardToken.balanceOf(FEE_RECEIVER);
    }

    // Operation wrappers
    function performStake(address user, uint256 amount) internal {
        hevm.prank(user);
        staking.stake(amount);
        _updateGhostState(user);
    }

    function performWithdraw(address user, uint256 amount) internal {
        hevm.prank(user);
        staking.withdraw(amount);
        _updateGhostState(user);
    }

    function performClaim(address user) internal {
        hevm.prank(user);
        staking.claimRewards();
        _updateGhostState(user);
    }

    function _warp(uint256 time) internal {
        hevm.warp(time);
    }
}