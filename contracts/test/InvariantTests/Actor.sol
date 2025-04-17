// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Actor
 * @notice Helper contract for testing access control and token interactions
 * @dev Used to simulate different user roles and their interactions with the protocol
 */
contract Actor {
    // Array of tokens this actor can interact with
    address[] public tokens;
    // Array of contracts this actor can interact with
    address[] public targetContracts;

    constructor(address[] memory _tokens, address[] memory _contracts) {
        tokens = _tokens;
        targetContracts = _contracts;
    }

    /**
     * @notice Proxy function to interact with target contracts
     * @param target The contract to interact with
     * @param callData The encoded function call data
     * @return success Whether the call was successful
     * @return returnData The data returned by the call
     */
    function proxy(address target, bytes memory callData) 
        external 
        returns (bool success, bytes memory returnData) 
    {
        require(_isValidTarget(target), "Invalid target contract");
        (success, returnData) = target.call(callData);
    }

    /**
     * @notice Approve token spending for a spender
     * @param token The token to approve
     * @param spender The address to approve
     * @param amount The amount to approve
     */
    function approveToken(address token, address spender, uint256 amount) external {
        require(_isValidToken(token), "Invalid token");
        IERC20(token).approve(spender, amount);
    }

    /**
     * @notice Check if a token is valid for this actor
     * @param token The token to check
     * @return bool Whether the token is valid
     */
    function _isValidToken(address token) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) return true;
        }
        return false;
    }

    /**
     * @notice Check if a contract is valid for this actor
     * @param target The contract to check
     * @return bool Whether the contract is valid
     */
    function _isValidTarget(address target) internal view returns (bool) {
        for (uint256 i = 0; i < targetContracts.length; i++) {
            if (targetContracts[i] == target) return true;
        }
        return false;
    }

    /**
     * @notice Helper function to get all tokens this actor can interact with
     * @return address[] The array of token addresses
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @notice Helper function to get all contracts this actor can interact with
     * @return address[] The array of contract addresses
     */
    function getTargetContracts() external view returns (address[] memory) {
        return targetContracts;
    }
}