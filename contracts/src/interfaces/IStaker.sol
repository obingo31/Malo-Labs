// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaker {
    // Role constants (add these)
    function PAUSE_GUARDIAN_ROLE() external view returns (bytes32);
    function REWARDS_ADMIN_ROLE() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    struct Reward {
        uint256 duration;
        uint256 rate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    // Public state variable getters
    function stakingToken() external view returns (IERC20);
    function totalStaked() external view returns (uint256);
    function paused() external view returns (bool);

    // User-specific getters
    function stakedBalanceOf(
        address user
    ) external view returns (uint256);
    function earned(address user, address token) external view returns (uint256);

    // Reward management
    function rewards(
        address token
    ) external view returns (Reward memory);
    function rewardTokens() external view returns (IERC20[] memory);

    // Access control
    function hasRole(bytes32 role, address account) external view returns (bool);
}
