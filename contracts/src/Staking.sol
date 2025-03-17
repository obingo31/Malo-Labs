// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RewardsDistributionRecipient.sol";
import {Constants} from "test/invariants/Constants.sol";
import {Errors} from "./libraries/Errors.sol";

/**
 * @title Staking Contract
 * @notice A contract for staking tokens and earning rewards.
 */
contract Staking is
    Constants, // Lowest-level constants
    AccessControl, // Role-based access
    ReentrancyGuard, // Reentrancy protection
    Pausable, // Pause functionality
    RewardsDistributionRecipient
{
    using SafeERC20 for IERC20;

    // Role to set the protocol fee and fee recipient
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    // The token that can be staked
    IERC20 public immutable stakingToken;

    // The recipient of protocol fees
    address public feeRecipient;

    // Timestamp when the current reward period finishes
    uint256 public periodFinish;

    // The rate at which rewards are distributed per second
    uint256 public rewardRate;

    // Timestamp of the last reward update
    uint256 public lastUpdateTime;

    // Reward per token stored, used for calculating earned rewards
    uint256 public rewardPerTokenStored;

    // Percentage of claimed rewards sent to `feeRecipient`
    uint256 public protocolFee;

    // Length of the reward distribution period
    uint256 public rewardPeriod;

    // Total rewards distributed to all users
    uint256 public totalRewardsDistributed;

    // Total number of tokens staked in the contract
    uint256 private _totalSupply;

    // Mapping of user addresses to their staked balances
    mapping(address => uint256) private _balances;

    // Mapping of user addresses to their reward per token paid
    mapping(address => uint256) public userRewardPerTokenPaid;

    // Mapping of user addresses to their claimable rewards
    mapping(address => uint256) public rewards;

    // Mapping of user addresses to the total rewards claimed
    mapping(address => uint256) public rewardsClaimed;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 netReward, uint256 totalClaimed);
    event RewardRateUpdated(uint256 newRate);
    event ProtocolFeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newRecipient);
    event RewardPeriodUpdated(uint256 newPeriod);
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 forfeitedRewards);

    constructor(
        address _stakingToken,
        address _maloToken,
        address initialOwner,
        uint256 _rewardPeriod,
        address _feeRecipient
    ) RewardsDistributionRecipient(initialOwner, _maloToken) {
        if (_stakingToken == address(0)) revert Errors.ZeroAddress();
        if (_maloToken == address(0)) revert Errors.ZeroAddress();
        if (_stakingToken == _maloToken) revert Errors.SameTokenAddresses();
        if (initialOwner == address(0)) revert Errors.ZeroAddress();
        if (_rewardPeriod == 0) revert Errors.InvalidRewardPeriod();
        if (_feeRecipient == address(0)) revert Errors.ZeroAddress();

        stakingToken = IERC20(_stakingToken);
        rewardPeriod = _rewardPeriod;
        feeRecipient = _feeRecipient;

        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(PAUSER_ROLE, initialOwner);
        _grantRole(FEE_SETTER_ROLE, initialOwner);
    }

    // Core staking functions
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) return rewardPerTokenStored;
        uint256 timeElapsed =
            block.timestamp > periodFinish ? periodFinish - lastUpdateTime : block.timestamp - lastUpdateTime;
        return rewardPerTokenStored + (timeElapsed * rewardRate * PRECISION_FACTOR) / _totalSupply;
    }

    function earned(address account) public view returns (uint256) {
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / PRECISION_FACTOR
            + rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp > periodFinish ? periodFinish : block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        if (amount == 0) revert Errors.ZeroAmount();
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert Errors.ZeroAmount();
        if (_balances[msg.sender] < amount) revert Errors.WithdrawAmountExceedsBalance();

        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert Errors.NoRewardsAvailable();

        uint256 fee = (reward * protocolFee) / 1000;
        uint256 netReward = reward - fee;

        rewards[msg.sender] = 0;
        rewardsClaimed[msg.sender] += reward;
        totalRewardsDistributed += reward; // Track total rewards distributed

        if (fee > 0) {
            maloToken.safeTransfer(feeRecipient, fee);
        }
        maloToken.safeTransfer(msg.sender, netReward);

        emit RewardPaid(msg.sender, netReward, rewardsClaimed[msg.sender]);
    }

    // Reward Management
    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution {
        _setRewardRate(reward / rewardPeriod);
    }

    function _setRewardRate(uint256 _rewardRate) internal updateReward(address(0)) {
        if (block.timestamp < periodFinish) revert Errors.PreviousPeriodActive();
        if (_rewardRate == 0) revert Errors.ZeroAmount();

        uint256 balance = maloToken.balanceOf(address(this));
        uint256 requiredBalance = _rewardRate * rewardPeriod;
        if (balance < requiredBalance) revert Errors.InsufficientBalance();

        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardPeriod;
        emit RewardRateUpdated(_rewardRate);
    }

    function setRewardRate(uint256 _rewardRate) external onlyRewardsDistribution {
        _setRewardRate(_rewardRate);
    }

    function setRewardPeriod(uint256 newPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newPeriod == 0) revert Errors.InvalidRewardPeriod();
        if (block.timestamp <= periodFinish) revert Errors.ActiveRewardsPeriod();
        rewardPeriod = newPeriod;
        emit RewardPeriodUpdated(newPeriod);
    }

    // Fee Management
    function setProtocolFee(uint256 newFee) external onlyRole(FEE_SETTER_ROLE) {
        if (newFee > 100) revert Errors.InvalidProtocolFee(); // 10% maximum (100 basis points)
        protocolFee = newFee;
        emit ProtocolFeeUpdated(newFee);
    }

    function setFeeRecipient(address newRecipient) external onlyRole(FEE_SETTER_ROLE) {
        if (newRecipient == address(0)) revert Errors.ZeroAddress();
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    // Emergency functions
    function emergencyWithdraw() external nonReentrant whenPaused {
        uint256 balance = _balances[msg.sender];
        if (balance == 0) revert Errors.InsufficientBalance();

        uint256 forfeited = rewards[msg.sender];
        _totalSupply -= balance;
        _balances[msg.sender] = 0;
        rewards[msg.sender] = 0;

        stakingToken.safeTransfer(msg.sender, balance);
        emit EmergencyWithdraw(msg.sender, balance, forfeited);
    }

    // View functions
    function totalStaked() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardPeriod;
    }
}
