// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IStaking is IAccessControl {
    // Core Functions
    function stake(
        uint256 amount
    ) external;
    function unstake(address _user, uint256 _amount, bytes memory data) external;
    function stakeFor(address _user, uint256 _amount, bytes calldata _data) external;
    function claimRewards() external;
    function emergencyWithdraw() external;

    // Admin Functions
    function setProtocolFee(
        uint256 fee
    ) external;
    function setRewardRate(
        uint256 rate
    ) external;
    function setRewardPeriod(
        uint256 period
    ) external;
    function setFeeRecipient(
        address recipient
    ) external;
    function pause() external;
    function unpause() external;

    // View Functions
    function balanceOf(
        address account
    ) external view returns (uint256);
    function earned(
        address account
    ) external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function totalRewardsDistributed() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function protocolFee() external view returns (uint256);
    function rewardPeriod() external view returns (uint256);
    function periodFinish() external view returns (uint256);
    function lastUpdateTime() external view returns (uint256);
    function paused() external view returns (bool);
    function feeRecipient() external view returns (address);

    // Constants
    function MAX_FEE() external view returns (uint256);
    function stakingToken() external view returns (IERC20);
    function rewardToken() external view returns (IERC20);

    // Role Management
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function FEE_SETTER_ROLE() external view returns (bytes32);
    function PAUSER_ROLE() external view returns (bytes32);
}
