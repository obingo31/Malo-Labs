// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStaker {
    struct Reward {
        uint256 duration;
        uint256 rate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    function rewards(address token) external view returns (Reward memory);
    function hasRole(bytes32 role, address account) external view returns (bool);
}
