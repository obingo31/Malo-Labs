// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IStaking is IAccessControl {
    // ─── Core User Functions ──────────────────────────────────────────────────

    /// @notice Stake tokens for yourself
    function stake(
        uint256 amount
    ) external;

    /// @notice Stake tokens on behalf of another user
    function stakeFor(address user, uint256 amount) external;

    /// @notice Unstake your tokens
    function unstake(
        uint256 amount
    ) external;

    /// @notice Claim any pending rewards
    function claimRewards() external;

    /// @notice Emergency withdraw your entire stake (forfeiting rewards)
    function emergencyWithdraw() external;

    /// @notice Transfer staked tokens to another user
    function transfer(address to, uint256 amount) external;

    /// @notice Transfer + unstake in one call
    function transferAndUnstake(address to, uint256 amount) external;

    // ─── Lock‐Manager Functions ────────────────────────────────────────────────

    function allowManager(address lockManager, uint256 allowance, bytes calldata data) external;
    function increaseLockAllowance(address lockManager, uint256 allowance) external;
    function decreaseLockAllowance(address user, address lockManager, uint256 allowance) external;
    function lock(address user, uint256 amount) external;
    function unlock(address user, address lockManager, uint256 amount) external;
    function unlockAndRemoveManager(address user, address lockManager) external;
    function slash(address from, address to, uint256 amount) external;
    function slashAndUnstake(address from, address to, uint256 amount) external;

    // ─── Admin / Governance Functions ────────────────────────────────────────

    function notifyRewardAmount(
        uint256 reward
    ) external;
    function setRewardRate(
        uint256 rate
    ) external;
    function setRewardPeriod(
        uint256 period
    ) external;
    function setProtocolFee(
        uint256 feeBps
    ) external;
    function setFeeRecipient(
        address recipient
    ) external;
    function pause() external;
    function unpause() external;
    function setRewardsDistribution(
        address distributor
    ) external;

    // ─── Views ────────────────────────────────────────────────────────────────

    function totalStaked() external view returns (uint256);
    function balanceOf(
        address account
    ) external view returns (uint256);
    function lockedBalanceOf(
        address account
    ) external view returns (uint256);
    function unlockedBalanceOf(
        address account
    ) external view returns (uint256);

    function earned(
        address account
    ) external view returns (uint256);
    function totalRewardsDistributed() external view returns (uint256);
    function rewardsClaimed(
        address account
    ) external view returns (uint256);

    function rewardRate() external view returns (uint256);
    function rewardPeriod() external view returns (uint256);
    function periodFinish() external view returns (uint256);
    function lastUpdateTime() external view returns (uint256);
    function getRewardForDuration() external view returns (uint256);

    function protocolFee() external view returns (uint256);
    function feeRecipient() external view returns (address);
    function lastNonZeroTotalSupply() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function userRewardPerTokenPaid(
        address account
    ) external view returns (uint256);

    // ─── Constants / Roles ─────────────────────────────────────────────────────

    function MAX_FEE() external view returns (uint256);
    function PRECISION_FACTOR() external view returns (uint256);

    function stakingToken() external view returns (IERC20);
    function maloToken() external view returns (IERC20);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function PAUSER_ROLE() external view returns (bytes32);
    function FEE_SETTER_ROLE() external view returns (bytes32);
    function LOCK_MANAGER_ROLE() external view returns (bytes32);
}
