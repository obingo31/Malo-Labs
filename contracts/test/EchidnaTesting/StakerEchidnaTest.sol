// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/Staker.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract StakerEchidnaTest {
    Staker public staker;
    MockERC20 public stakingToken;
    MockERC20[] public rewardTokens;

    address internal constant ADMIN = address(0x100);
    address internal constant GUARDIAN = address(0x200);
    address internal constant USER1 = address(0x300);
    address internal constant USER2 = address(0x400);

    uint256 internal constant INITIAL_MINT = 1_000_000 * 10 ** 18;
    uint256 internal constant REWARD_DURATION = 7 days;

    constructor() payable {
        // Deploy staking token and mint initial balance to test addresses
        stakingToken = new MockERC20("Staking Token", "STKN");
        stakingToken.mint(address(this), INITIAL_MINT);
        stakingToken.mint(ADMIN, INITIAL_MINT);
        stakingToken.mint(USER1, INITIAL_MINT);
        stakingToken.mint(USER2, INITIAL_MINT);

        // Initialize reward tokens: make sure to add at least one token.
        // (Following fuzzing tips: keep external dependencies to a minimum.)
        rewardTokens.push(new MockERC20("Reward Token", "RWD"));
        rewardTokens[0].mint(address(this), INITIAL_MINT);

        // Deploy staker contract with the staking token and proper roles.
        staker = new Staker(address(stakingToken), ADMIN, GUARDIAN);

        // Distribute initial tokens.
        stakingToken.transfer(USER1, 100_000 * 10 ** 18);
        stakingToken.transfer(USER2, 100_000 * 10 ** 18);

        // Setup initial rewards for each reward token.
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            staker.addReward(address(rewardTokens[i]), 50_000 * 10 ** 18, REWARD_DURATION);
        }
    }

    // ==== ECHIDNA INVARIANT TESTS ====
    // Invariants should always hold after any sequence of valid operations.
    // These tests document our expectations about staker internal state.

    // Invariant: The sum of individual staked balances must equal total staked.
    function echidna_totalStakedMatchesBalances() public view returns (bool) {
        uint256 total = staker.totalStaked();
        uint256 user1Balance = staker.stakedBalanceOf(USER1);
        uint256 user2Balance = staker.stakedBalanceOf(USER2);
        return total == (user1Balance + user2Balance);
    }

    // Invariant: The staking token balance held by the staker contract must cover all staked tokens.
    function echidna_contractBalanceCoversTotalStaked() public view returns (bool) {
        return stakingToken.balanceOf(address(staker)) >= staker.totalStaked();
    }

    // Invariant: For each reward token, its balance at the staker should cover the total amount staked.
    function echidna_rewardTokenBalanceCoversTotalStaked() public view returns (bool) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (rewardTokens[i].balanceOf(address(staker)) < staker.totalStaked()) {
                return false;
            }
        }
        return true;
    }

    // Helper function to bound a value within min and max.
    // (Use this for fuzzed input constraints elsewhere if needed.)
    function bound(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
        return min + (value % (max - min + 1));
    }
}
