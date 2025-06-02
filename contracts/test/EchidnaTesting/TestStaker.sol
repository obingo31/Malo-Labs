// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/Staker.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {MockERC20} from "../mocks/MockERC20.sol";

contract TestStaker {
    using SafeERC20 for IERC20;

    Staker public staker;
    MockERC20 public stakingToken;
    MockERC20 public rewardToken;

    // Test state tracking for invariants
    uint256 public totalRewardsAdded;
    uint256 public totalRewardsClaimed;
    mapping(address => uint256) public trackedUserBalances;

    constructor() {
        // Deploy tokens
        stakingToken = new MockERC20("Staking Token", "STK");
        rewardToken = new MockERC20("Reward Token", "REW");

        // Deploy staker with this contract as admin and guardian
        staker = new Staker(address(stakingToken), address(this), address(this));

        // Grant roles
        staker.grantRole(staker.REWARDS_ADMIN_ROLE(), address(this));
        staker.grantRole(staker.PAUSE_GUARDIAN_ROLE(), address(this));

        // Mint initial testing supply (use reasonable amounts)
        stakingToken.mint(address(this), 1_000_000 ether);
        rewardToken.mint(address(this), 1_000_000 ether);
    }

    // Echidna property: Total staked should match sum of individual balances
    function echidna_totalStakedMatchesBalances() public view returns (bool) {
        return staker.totalStaked() == trackedUserBalances[address(this)];
    }

    // Echidna property: Contract balance should cover total staked
    function echidna_balanceCoversTotalStaked() public view returns (bool) {
        return stakingToken.balanceOf(address(staker)) >= staker.totalStaked();
    }

    // Echidna property: Rewards claimed cannot exceed rewards added
    function echidna_rewardsClaimedUnderTotal() public view returns (bool) {
        return totalRewardsClaimed <= totalRewardsAdded;
    }

    // Helper function for input validation
    function bound(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
        require(min <= max, "Invalid bounds");
        return min + (value % (max - min + 1));
    }

    // Test function to stake tokens
    function testStake(
        uint256 amount
    ) public {
        // Bound amount to reasonable values
        amount = bound(amount, 1, 1_000_000 ether);

        // Track state before
        uint256 totalBefore = staker.totalStaked();
        uint256 userBalanceBefore = staker.stakedBalanceOf(address(this));
        uint256 contractBalanceBefore = stakingToken.balanceOf(address(staker));

        // Approve and stake
        stakingToken.approve(address(staker), amount);

        try staker.stake(amount) {
            // Update tracked balances
            trackedUserBalances[address(this)] += amount;

            // Verify state changes
            assert(staker.totalStaked() == totalBefore + amount);
            assert(staker.stakedBalanceOf(address(this)) == userBalanceBefore + amount);
            assert(stakingToken.balanceOf(address(staker)) == contractBalanceBefore + amount);
        } catch {
            // Stake might fail due to pause or invalid amount
        }
    }

    // Test function to add rewards
    function testAddReward(uint256 amount, uint256 duration) public {
        amount = bound(amount, 1 ether, 100_000 ether);
        duration = bound(duration, 1 days, 365 days);

        rewardToken.approve(address(staker), amount);

        try staker.addReward(address(rewardToken), amount, duration) {
            totalRewardsAdded += amount;
        } catch {
            // Adding reward might fail due to invalid parameters
        }
    }
}
