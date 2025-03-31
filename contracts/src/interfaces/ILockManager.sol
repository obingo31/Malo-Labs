// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILockManager
 * @dev Interface for contracts that can manage locks in the staking contract
 */
interface ILockManager {
    /**
     * @notice Checks if a user can unlock their tokens
     * @param _user Address of the user
     * @param _amount Amount the user wants to unlock
     * @return Whether the unlock is allowed
     */
    function canUnlock(address _user, uint256 _amount) external view returns (bool);
}
