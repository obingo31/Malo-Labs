// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IStaker} from "./interfaces/IStaker.sol";

contract Staker is IStaker, AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant REWARDS_ADMIN_ROLE = keccak256("REWARDS_ADMIN_ROLE");
    bytes32 public constant PAUSE_GUARDIAN_ROLE = keccak256("PAUSE_GUARDIAN_ROLE");

    IERC20 public immutable stakingToken;
    IERC20[] public rewardTokens;
    mapping(address => bool) public isRewardToken;

    struct Reward {
        uint256 duration;
        uint256 rate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    mapping(address => Reward) public rewards;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewardsEarned;

    uint256 private _totalStaked;
    mapping(address => uint256) private _stakedBalances;

    uint256 private constant MAX_REWARD_DURATION = 3650 days;

    constructor(address _stakingToken, address _admin, address _pauseGuardian) {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_admin != address(0), "Invalid admin address");
        require(_pauseGuardian != address(0), "Invalid pause guardian");

        stakingToken = IERC20(_stakingToken);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(REWARDS_ADMIN_ROLE, _admin);
        _grantRole(PAUSE_GUARDIAN_ROLE, _pauseGuardian);
    }

    function stake(
        uint256 amount
    ) external nonReentrant whenNotPaused validAmount(amount) {
        _updateRewards(msg.sender);

        _totalStaked += amount;
        _stakedBalances[msg.sender] += amount;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(
        uint256 amount
    ) external nonReentrant whenNotPaused validAmount(amount) {
        require(_stakedBalances[msg.sender] >= amount, "Insufficient balance");
        _updateRewards(msg.sender);

        _totalStaked -= amount;
        _stakedBalances[msg.sender] -= amount;

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards(
        address rewardToken
    ) external nonReentrant validAddress(rewardToken) {
        require(rewards[rewardToken].duration > 0, "Invalid reward token");
        _updateRewards(msg.sender);

        uint256 reward = rewardsEarned[msg.sender][rewardToken];
        require(reward > 0, "No rewards to claim");

        rewardsEarned[msg.sender][rewardToken] = 0;
        IERC20(rewardToken).safeTransfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, rewardToken, reward);
    }

    function addReward(
        address rewardToken,
        uint256 totalRewards,
        uint256 duration
    ) external onlyRole(REWARDS_ADMIN_ROLE) validAddress(rewardToken) validAmount(totalRewards) validAmount(duration) {
        require(duration <= MAX_REWARD_DURATION, "Duration exceeds maximum");

        Reward storage reward = rewards[rewardToken];
        if (reward.duration > 0) {
            require(block.timestamp >= reward.lastUpdateTime + reward.duration, "Previous reward ongoing");
            uint256 endTime = reward.lastUpdateTime + reward.duration;
            uint256 timeElapsed = endTime - reward.lastUpdateTime;
            if (_totalStaked > 0) {
                reward.rewardPerTokenStored += (timeElapsed * reward.rate * 1e18) / _totalStaked;
            }
            reward.lastUpdateTime = endTime;
        }

        uint256 currentBalance = IERC20(rewardToken).balanceOf(address(this));
        require(totalRewards >= currentBalance, "Insufficient new rewards");
        uint256 amountToTransfer = totalRewards - currentBalance;

        if (!isRewardToken[rewardToken]) {
            rewardTokens.push(IERC20(rewardToken));
            isRewardToken[rewardToken] = true;
        }

        uint256 rate = totalRewards / duration;
        reward.duration = duration;
        reward.rate = rate;
        reward.lastUpdateTime = block.timestamp;

        if (amountToTransfer > 0) {
            IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), amountToTransfer);
        }
        emit RewardAdded(rewardToken, totalRewards, duration);
    }

    function removeRewardToken(
        address rewardToken
    ) external onlyRole(REWARDS_ADMIN_ROLE) validAddress(rewardToken) {
        require(isRewardToken[rewardToken], "Not a reward token");
        require(
            block.timestamp >= rewards[rewardToken].lastUpdateTime + rewards[rewardToken].duration, "Reward ongoing"
        );

        isRewardToken[rewardToken] = false;

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (address(rewardTokens[i]) == rewardToken) {
                rewardTokens[i] = rewardTokens[rewardTokens.length - 1];
                rewardTokens.pop();
                break;
            }
        }
        emit RewardTokenRemoved(rewardToken);
    }

    function _updateRewards(
        address user
    ) internal {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = address(rewardTokens[i]);
            if (!isRewardToken[token]) continue;

            Reward storage reward = rewards[token];
            reward.rewardPerTokenStored = _rewardPerToken(token);
            reward.lastUpdateTime = lastTimeRewardApplicable(token);

            if (user != address(0)) {
                rewardsEarned[user][token] = earned(user, token);
                userRewardPerTokenPaid[user][token] = reward.rewardPerTokenStored;
            }
        }
    }

    function lastTimeRewardApplicable(
        address rewardToken
    ) public view returns (uint256) {
        Reward storage reward = rewards[rewardToken];
        return block.timestamp < reward.lastUpdateTime + reward.duration
            ? block.timestamp
            : reward.lastUpdateTime + reward.duration;
    }

    function _rewardPerToken(
        address rewardToken
    ) internal view returns (uint256) {
        Reward storage reward = rewards[rewardToken];
        if (_totalStaked == 0) return reward.rewardPerTokenStored;

        uint256 timeElapsed = lastTimeRewardApplicable(rewardToken) - reward.lastUpdateTime;
        return reward.rewardPerTokenStored + (timeElapsed * reward.rate * 1e18) / _totalStaked;
    }

    function earned(address user, address rewardToken) public view returns (uint256) {
        uint256 currentRewardPerToken = _rewardPerToken(rewardToken);
        uint256 paid = userRewardPerTokenPaid[user][rewardToken];
        if (currentRewardPerToken < paid) return rewardsEarned[user][rewardToken];

        uint256 delta = currentRewardPerToken - paid;
        uint256 newRewards = (_stakedBalances[user] * delta) / 1e18;
        return newRewards + rewardsEarned[user][rewardToken];
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function stakedBalanceOf(
        address user
    ) external view returns (uint256) {
        return _stakedBalances[user];
    }

    function claimAllRewards() external nonReentrant {
        _updateRewards(msg.sender);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = address(rewardTokens[i]);
            uint256 reward = rewardsEarned[msg.sender][token];
            if (reward > 0) {
                rewardsEarned[msg.sender][token] = 0;
                IERC20(token).safeTransfer(msg.sender, reward);
                emit RewardClaimed(msg.sender, token, reward);
            }
        }
    }

    function pause() external onlyRole(PAUSE_GUARDIAN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSE_GUARDIAN_ROLE) {
        _unpause();
    }

    /**
     * @notice Modifier to check if the provided address is valid.
     * @param _address to be checked for validity.
     */
    modifier validAddress(
        address _address
    ) {
        require(_address != address(0), "Invalid reward token");
        _;
    }

    /**
     * @notice Modifier to check if the provided amount is valid.
     * @param _amount to be checked for validity.
     */
    modifier validAmount(
        uint256 _amount
    ) {
        require(_amount > 0, "Cannot withdraw 0 or stake 0");
        _;
    }
}
