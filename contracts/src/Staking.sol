// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RewardsDistributionRecipient.sol";
// import {IStaking} from "./interfaces/IStaking.sol";
import "./Constants.sol";
import "./Errors.sol";

contract Staking is IStaking, RewardsDistributionRecipient, AccessControl, ReentrancyGuard, Pausable, Constants, Errors {
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    IERC20 public immutable stakingToken;
    address public feeRecipient;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public protocolFee;
    uint256 public rewardPeriod;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public rewardsClaimed;

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
        if (_stakingToken == address(0)) revert ZeroAddress();
        if (_maloToken == address(0)) revert ZeroAddress();
        if (_stakingToken == _maloToken) revert SameTokenAddresses();
        if (initialOwner == address(0)) revert ZeroAddress();
        if (_rewardPeriod == 0) revert InvalidRewardPeriod();
        if (_feeRecipient == address(0)) revert ZeroAddress();

        stakingToken = IERC20(_stakingToken);
        rewardPeriod = _rewardPeriod;
        feeRecipient = _feeRecipient;

        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(PAUSER_ROLE, initialOwner);
        _grantRole(FEE_SETTER_ROLE, initialOwner);
    }

    // ─────────────────────────────────────────────────────────────
    // Core Staking Functions
    // ─────────────────────────────────────────────────────────────

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
        if (amount == 0) revert ZeroAmount();
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert ZeroAmount();
        if (_balances[msg.sender] < amount) revert WithdrawAmountExceedsBalance();
        
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert NoRewardsAvailable();

        uint256 fee = (reward * protocolFee) / 1000;
        uint256 netReward = reward - fee;

        rewards[msg.sender] = 0;
        rewardsClaimed[msg.sender] += reward;

        if (fee > 0) {
            maloToken.safeTransfer(feeRecipient, fee);
        }
        maloToken.safeTransfer(msg.sender, netReward);

        emit RewardPaid(msg.sender, netReward, rewardsClaimed[msg.sender]);
    }

    // ─────────────────────────────────────────────────────────────
    // Reward Management
    // ─────────────────────────────────────────────────────────────

    function setRewardRate(uint256 _rewardRate) external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp < periodFinish) revert PreviousPeriodActive();
        if (_rewardRate == 0) revert ZeroAmount();

        uint256 balance = maloToken.balanceOf(address(this));
        uint256 requiredBalance = _rewardRate * rewardPeriod;
        if (balance < requiredBalance) revert InsufficientBalance();

        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardPeriod;
        emit RewardRateUpdated(_rewardRate);
    }

    function setRewardPeriod(uint256 newPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newPeriod == 0) revert InvalidRewardPeriod();
        if (block.timestamp <= periodFinish) revert ActiveRewardsPeriod();
        rewardPeriod = newPeriod;
        emit RewardPeriodUpdated(newPeriod);
    }

    // ─────────────────────────────────────────────────────────────
    // Fee Management
    // ─────────────────────────────────────────────────────────────

    function setProtocolFee(uint256 newFee) external onlyRole(FEE_SETTER_ROLE) {
        if (newFee > 100) revert InvalidProtocolFee(); // 10% maximum (100 basis points)
        protocolFee = newFee;
        emit ProtocolFeeUpdated(newFee);
    }

    function setFeeRecipient(address newRecipient) external onlyRole(FEE_SETTER_ROLE) {
        if (newRecipient == address(0)) revert ZeroAddress();
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    // ─────────────────────────────────────────────────────────────
    // Emergency Functions
    // ─────────────────────────────────────────────────────────────

    function emergencyWithdraw() external nonReentrant whenPaused {
        uint256 balance = _balances[msg.sender];
        if (balance == 0) revert InsufficientBalance();

        uint256 forfeited = rewards[msg.sender];
        _totalSupply -= balance;
        _balances[msg.sender] = 0;
        rewards[msg.sender] = 0;

        stakingToken.safeTransfer(msg.sender, balance);
        emit EmergencyWithdraw(msg.sender, balance, forfeited);
    }

    // ─────────────────────────────────────────────────────────────
    // View Functions
    // ─────────────────────────────────────────────────────────────

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