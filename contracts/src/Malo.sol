// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {rewardToken} from "../test/mocks/rewardToken.sol";

contract MALO is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant REWARDS_ADMIN_ROLE = keccak256("REWARDS_ADMIN_ROLE");
    bytes32 public constant LIQUIDITY_GUARDIAN_ROLE = keccak256("LIQUIDITY_GUARDIAN_ROLE");

    IERC20 public immutable stakingToken;
    IERC20 public immutable malToken;

    // Reward system
    uint256 public rewardDuration = 7 days;
    uint256 public rewardRate;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    // Staking tracking
    uint256 private _totalStaked;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public lastStakeTime;

    // Vesting system
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public vestingStart;
    mapping(address => uint256) public totalVested;

    // Fee configuration
    uint256 public claimLockPeriod = 1 days;
    uint256 public maxDailyClaimPercent = 10;
    uint256 public withdrawalFeeBps = 50; // 0.5%
    uint256 public constant MAX_FEE_BPS = 1000;
    address public feeReceiver;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event RewardPaid(address indexed user, uint256 amount, uint256 fee);
    event RewardAdded(uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event FeeConfigUpdated(uint256 newFeeBps, address newReceiver);
    event RewardParametersUpdated(uint256 newRate, uint256 duration, uint256 totalRewards);

    constructor(address _stakingToken, address _malToken, address _admin, address _liquidityGuardian) {
        require(_stakingToken != address(0) && _malToken != address(0), "Zero address");
        require(_admin != address(0) && _liquidityGuardian != address(0), "Invalid roles");

        stakingToken = IERC20(_stakingToken);
        malToken = IERC20(_malToken);
        feeReceiver = _admin;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(REWARDS_ADMIN_ROLE, _admin);
        _grantRole(LIQUIDITY_GUARDIAN_ROLE, _liquidityGuardian);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                             Core                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    function stake(
        uint256 amount
    ) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        _totalStaked += amount;
        _balances[msg.sender] += amount;
        lastStakeTime[msg.sender] = block.timestamp;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(
        uint256 amount
    ) public nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0 && _balances[msg.sender] >= amount, "Invalid amount");

        uint256 fee = 0;
        if (block.timestamp < lastStakeTime[msg.sender] + claimLockPeriod) {
            fee = (amount * withdrawalFeeBps) / MAX_FEE_BPS;
            amount -= fee;
            if (fee > 0) stakingToken.safeTransfer(feeReceiver, fee);
        }

        _totalStaked -= (amount + fee);
        _balances[msg.sender] -= (amount + fee);

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, fee);
    }

    function claimRewards() public nonReentrant whenNotPaused updateReward(msg.sender) {
        uint256 totalReward = rewards[msg.sender];
        require(totalReward > 0, "No rewards");
        require(block.timestamp >= vestingStart[msg.sender] + claimLockPeriod, "Vesting active");

        uint256 elapsed = block.timestamp - vestingStart[msg.sender];
        uint256 maxClaim = (totalVested[msg.sender] * elapsed) / claimLockPeriod;
        uint256 claimAmount = totalReward > maxClaim ? maxClaim : totalReward;

        // Calculate and deduct fee
        uint256 fee = (claimAmount * withdrawalFeeBps) / MAX_FEE_BPS;
        uint256 netAmount = claimAmount - fee;

        rewards[msg.sender] = totalReward - claimAmount;
        vestingStart[msg.sender] = block.timestamp;
        totalVested[msg.sender] = rewards[msg.sender];

        if (fee > 0) malToken.safeTransfer(feeReceiver, fee);
        malToken.safeTransfer(msg.sender, netAmount);

        emit RewardPaid(msg.sender, netAmount, fee);
    }

    // Administration functions -----------------------------------------------
    function notifyRewardAmount(
        uint256 reward
    ) external onlyRole(REWARDS_ADMIN_ROLE) updateReward(address(0)) {
        require(reward > 0, "No reward");
        require(reward >= rewardDuration, "Reward too small");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardDuration;
            periodFinish = block.timestamp + rewardDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / remaining;
            // Maintain original end time
        }

        malToken.safeTransferFrom(msg.sender, address(this), reward);
        lastUpdateTime = block.timestamp;

        emit RewardAdded(reward);
        emit RewardParametersUpdated(rewardRate, periodFinish - block.timestamp, reward);
    }

    function setFeeConfig(
        uint256 newClaimFeeBps,
        uint256 newWithdrawalFeeBps,
        address newReceiver
    ) external onlyRole(LIQUIDITY_GUARDIAN_ROLE) {
        require(newClaimFeeBps <= MAX_FEE_BPS && newWithdrawalFeeBps <= MAX_FEE_BPS, "Fee too high");
        require(newReceiver != address(0), "Invalid receiver");

        withdrawalFeeBps = newWithdrawalFeeBps;
        feeReceiver = newReceiver;
        emit FeeConfigUpdated(newWithdrawalFeeBps, newReceiver);
    }

    function setRewardDuration(
        uint256 newDuration
    ) external onlyRole(REWARDS_ADMIN_ROLE) {
        require(newDuration > 0, "Invalid duration");
        rewardDuration = newDuration;
    }

    function setAntiDumpParams(uint256 lockPeriod, uint256 maxPercent) external onlyRole(LIQUIDITY_GUARDIAN_ROLE) {
        require(maxPercent <= 100, "Invalid percentage");
        claimLockPeriod = lockPeriod;
        maxDailyClaimPercent = maxPercent;
    }

    function emergencyWithdraw() external nonReentrant whenPaused {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "No stake");

        _totalStaked -= amount;
        _balances[msg.sender] = 0;
        rewards[msg.sender] = 0;

        stakingToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    // Views ------------------------------------------------------------------
    function rewardPerToken() public view returns (uint256) {
        if (_totalStaked == 0) return rewardPerTokenStored;
        uint256 timeElapsed =
            block.timestamp < periodFinish ? block.timestamp - lastUpdateTime : periodFinish - lastUpdateTime;
        return rewardPerTokenStored + (timeElapsed * rewardRate * 1e18) / _totalStaked;
    }

    function earned(
        address account
    ) public view returns (uint256) {
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    // Modifiers -------------------------------------------------------------
    modifier updateReward(
        address account
    ) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp < periodFinish ? block.timestamp : periodFinish;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
            if (vestingStart[account] == 0) {
                vestingStart[account] = block.timestamp;
                totalVested[account] = rewards[account];
            }
        }
        _;
    }
}
