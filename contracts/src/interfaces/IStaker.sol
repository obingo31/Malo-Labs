// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IStaker
 * @notice Interface for multi-reward token staking contract.
 */
interface IStaker {
    // -- Events --

    /**
     * @notice Event emitted when participant staked tokens.
     * @param user The address of the participant.
     * @param amount The amount staked.
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @notice Event emitted when participant withdrew tokens.
     * @param user The address of the participant.
     * @param amount The amount withdrawn.
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @notice Event emitted when rewards were added for a token.
     * @param token The reward token address.
     * @param amount The amount of rewards added.
     * @param duration The duration of the reward period.
     */

    /**
     * @notice Event emitted when participant claimed rewards.
     * @param user The address of the participant.
     * @param token The reward token address.
     * @param amount The amount of rewards claimed.
     */
    event RewardClaimed(address indexed user, address indexed token, uint256 amount);

    /**
     * @notice Event emitted when a reward token was removed.
     * @param token The reward token address that was removed.
     */
    event RewardTokenRemoved(address indexed token);

    event RewardAdded(address indexed token, uint256 amount, uint256 duration);

    // -- Core Token Information --

    /**
     * @notice Address of the staking token.
     */
    function stakingToken() external view returns (IERC20);

    /**
     * @notice Array of reward tokens.
     * @param index The index of the reward token.
     */
    function rewardTokens(
        uint256 index
    ) external view returns (IERC20);

    /**
     * @notice Check if a token is a valid reward token.
     * @param token The token address to check.
     */
    function isRewardToken(
        address token
    ) external view returns (bool);

    // -- Reward Information --

    /**
     * @notice Get reward information for a specific token.
     * @param rewardToken The reward token address.
     * @return duration The duration of the reward period.
     * @return rate The reward rate per second.
     * @return lastUpdateTime The last time rewards were updated.
     * @return rewardPerTokenStored The stored reward per token value.
     */
    function rewards(
        address rewardToken
    ) external view returns (uint256 duration, uint256 rate, uint256 lastUpdateTime, uint256 rewardPerTokenStored);

    /**
     * @notice Get the amount of reward per token paid to a user for a specific reward token.
     * @param user The user address.
     * @param rewardToken The reward token address.
     */
    function userRewardPerTokenPaid(address user, address rewardToken) external view returns (uint256);

    /**
     * @notice Get the earned rewards for a user for a specific reward token.
     * @param user The user address.
     * @param rewardToken The reward token address.
     */
    function rewardsEarned(address user, address rewardToken) external view returns (uint256);

    // -- User Actions --

    /**
     * @notice Stakes tokens for the caller.
     * @param amount The amount to stake.
     */
    function stake(
        uint256 amount
    ) external;

    /**
     * @notice Withdraws staked tokens for the caller.
     * @param amount The amount to withdraw.
     */
    function withdraw(
        uint256 amount
    ) external;

    /**
     * @notice Claims rewards for a specific reward token.
     * @param rewardToken The address of the reward token to claim.
     */
    function claimRewards(
        address rewardToken
    ) external;

    /**
     * @notice Claims all available rewards for the caller.
     */
    function claimAllRewards() external;

    // -- Administration --

    /**
     * @notice Adds rewards for a specific token.
     * @param rewardToken The reward token address.
     * @param totalRewards The total amount of rewards to distribute.
     * @param duration The duration over which to distribute rewards.
     */
    function addReward(address rewardToken, uint256 totalRewards, uint256 duration) external;

    /**
     * @notice Removes a reward token from the system.
     * @param rewardToken The reward token address to remove.
     */
    function removeRewardToken(
        address rewardToken
    ) external;

    // -- View Functions --

    /**
     * @notice Returns the total amount of tokens staked.
     */
    function totalStaked() external view returns (uint256);

    /**
     * @notice Returns the staked balance for a specific user.
     * @param user The user address.
     */
    function stakedBalanceOf(
        address user
    ) external view returns (uint256);

    /**
     * @notice Returns the last time rewards were applicable for a specific reward token.
     * @param rewardToken The reward token address.
     */
    function lastTimeRewardApplicable(
        address rewardToken
    ) external view returns (uint256);

    /**
     * @notice Returns the earned rewards for a user for a specific reward token.
     * @param user The user address.
     * @param rewardToken The reward token address.
     */
    function earned(address user, address rewardToken) external view returns (uint256);

    // -- Role Constants --

    /**
     * @notice Role identifier for rewards administrators.
     */
    function REWARDS_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Role identifier for pause guardians.
     */
    function PAUSE_GUARDIAN_ROLE() external view returns (bytes32);
}
