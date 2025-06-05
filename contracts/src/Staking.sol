// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./RewardsDistributionRecipient.sol";
import {Constants} from "./Constants.sol";
import {Errors} from "./libraries/Errors.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {ILockManager} from "./interfaces/ILockManager.sol";

contract Staking is Constants, AccessControl, ReentrancyGuard, Pausable, RewardsDistributionRecipient {
    /**
     * @title Staking Contract
     * @notice A contract for staking tokens and earning rewards with locking functionality.
     */
    using SafeERC20 for IERC20;

    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    bytes32 public constant LOCK_MANAGER_ROLE = keccak256("LOCK_MANAGER_ROLE");

    IERC20 public immutable stakingToken;

    address public feeRecipient;

    uint256 public periodFinish;

    uint256 public rewardRate;

    uint256 public lastUpdateTime;

    uint256 public rewardPerTokenStored;

    uint256 public protocolFee;

    uint256 public rewardPeriod;

    uint256 public totalRewardsDistributed;

    uint256 private _totalSupply;

    uint256 public lastNonZeroTotalSupply;

    struct Lock {
        uint256 amount;
        uint256 allowance;
    }

    struct Account {
        mapping(address => Lock) locks;
        uint256 totalLocked;
    }

    mapping(address => uint256) private _balances;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public rewardsClaimed;
    mapping(address => Account) private _accounts;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 netReward, uint256 totalClaimed);
    event RewardRateUpdated(uint256 newRate);
    event ProtocolFeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newRecipient);
    event RewardPeriodUpdated(uint256 newPeriod);
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 forfeitedRewards);
    event StakeTransferred(address indexed from, address indexed to, uint256 amount);
    event NewLockManager(address indexed user, address indexed lockManager, bytes data);
    event LockAllowanceChanged(address indexed user, address indexed lockManager, uint256 newAllowance);
    event LockAmountChanged(address indexed user, address indexed lockManager, uint256 newAmount);
    event LockManagerRemoved(address indexed user, address indexed lockManager);

    // Fee Management
    uint256 public constant MAX_FEE = 100; // 10% in basis points

    modifier updateReward(
        address account
    ) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp > periodFinish ? periodFinish : block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

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
        _grantRole(LOCK_MANAGER_ROLE, initialOwner);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Returns the reward per token
    function rewardPerToken() public view returns (uint256) {
        uint256 effectiveSupply = _totalSupply;
        if (effectiveSupply == 0) {
            effectiveSupply = lastNonZeroTotalSupply;
            if (effectiveSupply == 0) {
                effectiveSupply = 1;
            }
        }
        uint256 timeElapsed =
            block.timestamp > periodFinish ? periodFinish - lastUpdateTime : block.timestamp - lastUpdateTime;
        return rewardPerTokenStored + (timeElapsed * rewardRate * PRECISION_FACTOR) / effectiveSupply;
    }

    function earned(
        address account
    ) public view returns (uint256) {
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / PRECISION_FACTOR
            + rewards[account];
    }

    /// @notice Stake tokens for the caller
    /// @param amount The amount of tokens to stake
    function stake(
        uint256 amount
    ) external nonReentrant whenNotPaused updateReward(msg.sender) {
        _stakeFor(msg.sender, msg.sender, amount);
    }

    /// @notice Stake tokens on behalf of another user
    /// @param _user The user to stake for
    /// @param _amount The amount of tokens to stake
    function stakeFor(address _user, uint256 _amount) external nonReentrant whenNotPaused updateReward(_user) {
        _stakeFor(msg.sender, _user, _amount);
    }

    /// @notice Unstake tokens
    /// @param _amount The amount of tokens to unstake
    function unstake(
        uint256 _amount
    ) external nonReentrant whenNotPaused updateReward(msg.sender) {
        if (_amount == 0) revert Errors.ZeroAmount();
        _unstake(msg.sender, _amount);
    }

    /// @notice Claim accumulated rewards
    function claimRewards() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert Errors.NoRewardsAvailable();

        uint256 fee = (reward * protocolFee) / 1000;
        uint256 netReward = reward - fee;

        rewards[msg.sender] = 0;
        rewardsClaimed[msg.sender] += reward;
        totalRewardsDistributed += reward;

        if (fee > 0) {
            maloToken.safeTransfer(feeRecipient, fee);
        }
        maloToken.safeTransfer(msg.sender, netReward);

        emit RewardPaid(msg.sender, netReward, rewardsClaimed[msg.sender]);
    }

    // Lock Management Functions
    /// @notice Allow a lock manager to lock a portion of your staked tokens
    /// @param _lockManager Address of the lock manager
    /// @param _allowance Amount of tokens the manager can lock
    /// @param _data Additional data to pass to the lock manager
    function allowManager(
        address _lockManager,
        uint256 _allowance,
        bytes calldata _data
    ) external nonReentrant whenNotPaused {
        Lock storage lock_ = _accounts[msg.sender].locks[_lockManager];
        if (lock_.allowance > 0) revert Errors.LockAlreadyExists();
        if (_allowance == 0) revert Errors.ZeroAmount();

        emit NewLockManager(msg.sender, _lockManager, _data);

        _increaseLockAllowance(msg.sender, _lockManager, lock_, _allowance);
    }

    /// @notice Increase the allowance for a lock manager
    /// @param _lockManager Address of the lock manager
    /// @param _allowance Additional allowance to grant
    function increaseLockAllowance(address _lockManager, uint256 _allowance) external nonReentrant whenNotPaused {
        Lock storage lock_ = _accounts[msg.sender].locks[_lockManager];
        if (lock_.allowance == 0) revert Errors.LockDoesNotExist();
        if (_allowance == 0) revert Errors.ZeroAmount();

        _increaseLockAllowance(msg.sender, _lockManager, lock_, _allowance);
    }

    /// @notice Decrease the allowance for a lock manager
    /// @param _user Owner of the locked tokens
    /// @param _lockManager Address of the lock manager
    /// @param _allowance Amount to decrease allowance by
    function decreaseLockAllowance(
        address _user,
        address _lockManager,
        uint256 _allowance
    ) external nonReentrant whenNotPaused {
        if (msg.sender != _user && msg.sender != _lockManager) revert Errors.NotAuthorized();
        if (_allowance == 0) revert Errors.ZeroAmount();

        Lock storage lock_ = _accounts[_user].locks[_lockManager];
        if (lock_.allowance == 0) revert Errors.LockDoesNotExist();

        uint256 newAllowance = lock_.allowance - _allowance;
        if (newAllowance < lock_.amount) revert Errors.InsufficientAllowance();
        if (newAllowance == 0) revert Errors.AllowanceCannotBeZero();

        lock_.allowance = newAllowance;
        emit LockAllowanceChanged(_user, _lockManager, newAllowance);
    }

    /// @notice Lock tokens of a user
    /// @param _user User whose tokens will be locked
    /// @param _amount Amount of tokens to lock
    function lock(address _user, uint256 _amount) external nonReentrant whenNotPaused onlyRole(LOCK_MANAGER_ROLE) {
        if (_amount == 0) revert Errors.ZeroAmount();

        uint256 unlocked = unlockedBalanceOf(_user);
        if (_amount > unlocked) revert Errors.InsufficientBalance();

        Account storage account = _accounts[_user];
        Lock storage lock_ = account.locks[msg.sender];
        if (lock_.allowance == 0) revert Errors.LockDoesNotExist();

        uint256 newAmount = lock_.amount + _amount;
        if (newAmount > lock_.allowance) revert Errors.InsufficientAllowance();

        lock_.amount = newAmount;
        account.totalLocked += _amount;

        emit LockAmountChanged(_user, msg.sender, newAmount);
    }

    /// @notice Unlock tokens for a user
    /// @param _user User whose tokens will be unlocked
    /// @param _lockManager Lock manager address
    /// @param _amount Amount of tokens to unlock
    function unlock(address _user, address _lockManager, uint256 _amount) external nonReentrant whenNotPaused {
        if (_amount == 0) revert Errors.ZeroAmount();
        if (!_canUnlock(msg.sender, _user, _lockManager, _amount)) revert Errors.CannotUnlock();

        _unlockUnsafe(_user, _lockManager, _amount);
    }

    /// @notice Unlock all tokens and remove lock manager
    /// @param _user User whose tokens will be unlocked
    /// @param _lockManager Lock manager to remove
    function unlockAndRemoveManager(address _user, address _lockManager) external nonReentrant whenNotPaused {
        if (!_canUnlock(msg.sender, _user, _lockManager, 0)) revert Errors.CannotUnlock();

        Account storage account = _accounts[_user];
        Lock storage lock_ = account.locks[_lockManager];

        uint256 amount = lock_.amount;
        account.totalLocked -= amount;

        emit LockAmountChanged(_user, _lockManager, 0);
        emit LockManagerRemoved(_user, _lockManager);

        delete account.locks[_lockManager];
    }

    /// @notice Slash locked tokens from one user to another
    /// @param _from User to slash from
    /// @param _to User to transfer tokens to
    /// @param _amount Amount to slash
    function slash(
        address _from,
        address _to,
        uint256 _amount
    ) external nonReentrant whenNotPaused onlyRole(LOCK_MANAGER_ROLE) {
        if (_amount == 0) revert Errors.ZeroAmount();
        _unlockUnsafe(_from, msg.sender, _amount);
        _transfer(_from, _to, _amount);
    }

    /// @notice Slash tokens and immediately unstake them to recipient
    /// @param _from User to slash from
    /// @param _to Recipient address
    /// @param _amount Amount to slash and unstake
    function slashAndUnstake(
        address _from,
        address _to,
        uint256 _amount
    ) external nonReentrant whenNotPaused onlyRole(LOCK_MANAGER_ROLE) {
        if (_amount == 0) revert Errors.ZeroAmount();
        _unlockUnsafe(_from, msg.sender, _amount);
        _transferAndUnstake(_from, _to, _amount);
    }

    /// @notice Transfer staked tokens to another user
    /// @param _to Recipient address
    /// @param _amount Amount to transfer
    function transfer(address _to, uint256 _amount) external nonReentrant whenNotPaused {
        _transfer(msg.sender, _to, _amount);
    }

    /// @notice Transfer and unstake tokens directly to a recipient
    /// @param _to Recipient address
    /// @param _amount Amount to transfer and unstake
    function transferAndUnstake(address _to, uint256 _amount) external nonReentrant whenNotPaused {
        _transferAndUnstake(msg.sender, _to, _amount);
    }

    // Reward Management
    function notifyRewardAmount(
        uint256 reward
    ) external override onlyRewardsDistribution {
        _setRewardRate(reward / rewardPeriod);
    }

    function _setRewardRate(
        uint256 _rewardRate
    ) internal updateReward(address(0)) {
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

    function setRewardRate(
        uint256 _rewardRate
    ) external onlyRewardsDistribution {
        _setRewardRate(_rewardRate);
    }

    function setRewardPeriod(
        uint256 newPeriod
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newPeriod == 0) revert Errors.InvalidRewardPeriod();
        if (block.timestamp <= periodFinish) revert Errors.ActiveRewardsPeriod();
        rewardPeriod = newPeriod;
        emit RewardPeriodUpdated(newPeriod);
    }

    function setProtocolFee(
        uint256 newFee
    ) external onlyRole(FEE_SETTER_ROLE) {
        if (newFee > MAX_FEE) revert Errors.InvalidProtocolFee();
        protocolFee = newFee;
        emit ProtocolFeeUpdated(newFee);
    }

    function setFeeRecipient(
        address newRecipient
    ) external onlyRole(FEE_SETTER_ROLE) {
        if (newRecipient == address(0)) revert Errors.ZeroAddress();
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    // Emergency functions
    function emergencyWithdraw() external nonReentrant whenPaused {
        uint256 balance = _balances[msg.sender];
        if (balance == 0) revert Errors.InsufficientBalance();
        if (_accounts[msg.sender].totalLocked > 0) revert Errors.LockedTokensExist();

        uint256 forfeited = rewards[msg.sender];
        _totalSupply -= balance;
        _balances[msg.sender] = 0;
        rewards[msg.sender] = 0;

        stakingToken.safeTransfer(msg.sender, balance);
        emit EmergencyWithdraw(msg.sender, balance, forfeited);
    }

    // Internal functions
    function _stakeFor(address _from, address _to, uint256 _amount) internal {
        if (_amount == 0) revert Errors.ZeroAmount();

        _totalSupply += _amount;
        _balances[_to] += _amount;
        if (_totalSupply > 0) {
            lastNonZeroTotalSupply = _totalSupply;
        }

        stakingToken.safeTransferFrom(_from, address(this), _amount);
        emit Staked(_to, _amount);
    }

    function _unstake(address _user, uint256 _amount) internal {
        if (_amount > _balances[_user]) revert Errors.InsufficientBalance();
        if (_amount > unlockedBalanceOf(_user)) revert Errors.LockedTokens();

        _totalSupply -= _amount;
        _balances[_user] -= _amount;
        if (_totalSupply > 0) {
            lastNonZeroTotalSupply = _totalSupply;
        }

        stakingToken.safeTransfer(_user, _amount);
        emit Withdrawn(_user, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        if (_amount == 0) revert Errors.ZeroAmount();
        if (_amount > _balances[_from]) revert Errors.InsufficientBalance();
        if (_amount > unlockedBalanceOf(_from)) revert Errors.LockedTokens();

        _balances[_from] -= _amount;
        _balances[_to] += _amount;
        emit StakeTransferred(_from, _to, _amount);
    }

    function _transferAndUnstake(address _from, address _to, uint256 _amount) internal {
        if (_amount == 0) revert Errors.ZeroAmount();
        if (_amount > _balances[_from]) revert Errors.InsufficientBalance();
        if (_amount > unlockedBalanceOf(_from)) revert Errors.LockedTokens();

        _totalSupply -= _amount;
        _balances[_from] -= _amount;
        if (_totalSupply > 0) {
            lastNonZeroTotalSupply = _totalSupply;
        }

        stakingToken.safeTransfer(_to, _amount);
        emit Withdrawn(_from, _amount);
    }

    function _increaseLockAllowance(
        address _user,
        address _lockManager,
        Lock storage _lock,
        uint256 _allowance
    ) internal {
        if (_allowance == 0) revert Errors.ZeroAmount();

        uint256 newAllowance = _lock.allowance + _allowance;
        _lock.allowance = newAllowance;

        emit LockAllowanceChanged(_user, _lockManager, newAllowance);
    }

    function _unlockUnsafe(address _user, address _lockManager, uint256 _amount) internal {
        Account storage account = _accounts[_user];
        Lock storage lock_ = account.locks[_lockManager];

        if (lock_.amount < _amount) revert Errors.InsufficientLock();

        lock_.amount -= _amount;
        account.totalLocked -= _amount;

        emit LockAmountChanged(_user, _lockManager, lock_.amount);
    }

    // View functions
    function totalStaked() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view returns (uint256) {
        return _balances[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardPeriod;
    }

    function lockedBalanceOf(
        address _user
    ) public view returns (uint256) {
        return _accounts[_user].totalLocked;
    }

    function unlockedBalanceOf(
        address _user
    ) public view returns (uint256) {
        return _balances[_user] - lockedBalanceOf(_user);
    }

    function getLock(address _user, address _lockManager) external view returns (uint256 amount, uint256 allowance) {
        Lock storage lock_ = _accounts[_user].locks[_lockManager];
        amount = lock_.amount;
        allowance = lock_.allowance;
    }

    function _canUnlock(
        address _sender,
        address _user,
        address _lockManager,
        uint256 _amount
    ) internal view returns (bool) {
        Lock storage lock_ = _accounts[_user].locks[_lockManager];
        if (lock_.allowance == 0) return false;

        uint256 amount = _amount == 0 ? lock_.amount : _amount;
        if (lock_.amount < amount) return false;

        if (_sender == _lockManager) return true;

        if (_sender != _user) return false;

        if (amount == 0) return true;

        return ILockManager(_lockManager).canUnlock(_user, amount);
    }

    // Add this function inside your Staking contract
    function rewardTokens() public view returns (IERC20[] memory) {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = maloToken;
        return tokens;
    }
}
