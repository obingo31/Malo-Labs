// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract Properties is BeforeAfter, Asserts {
    using SafeCast for uint256;

    uint256 public constant MAX_PROTOCOL_FEE = 1000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Core Invariants                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Ensures core functions don't revert with valid inputs
    /// @return True if all core functions pass
    ///@param actors The list of actors to test
    function invariant_operations_with_valid_inputs() public view returns (bool) {
        _verifyValidOperation(OperationType.Stake);
        _verifyValidOperation(OperationType.Withdraw);
        _verifyValidOperation(OperationType.Claim);
        return true;
    }

    /// @dev Ensures arithmetic safety in all protocol calculations
    /// @return True if all arithmetic operations are safe
    ///@param liquidity checks
    ///@param overflow checks
    function invariant_arithmetic_safety() public view returns (bool) {
        _verifyNoOverflow(staking.totalSupply(), "Total supply overflow");
        _verifyNoOverflow(staking.totalRewards(), "Total rewards overflow");
        _verifyNoOverflow(staking.rewardRate(), "Reward rate overflow");
        return true;
    }

    /// @dev Ensures reward parameters remain within safe bounds
    /// @return True if all reward parameters are safe
    function invariant_reward_parameters() public view returns (bool) {
        uint256 rewardRate = staking.rewardRate();
        require(rewardRate <= _safeRewardRateBound(), "Reward rate exceeds safe bound");
        require(staking.protocolFee() <= MAX_PROTOCOL_FEE, "Protocol fee exceeds maximum");
        return true;
    }

    enum OperationType {
        Stake,
        Withdraw,
        Claim
    }

    /// @dev Verifies that a valid operation can be executed
    /// @param opType The type of operation to verify
    /// @return True if the operation is valid
    /// @return The user address with a valid balance
    /// The function selects a user with a valid balance for the operation
    /// and verifies that the operation can be executed without reverting.

    function _verifyValidOperation(OperationType opType) internal view {
        address user = _selectUserWithBalance(opType);
        if (user == address(0)) return; // No valid users for operation

        uint256 amount = opType == OperationType.Stake ? _getValidStakeAmount(user) : _getValidWithdrawAmount(user);

        if (amount == 0) return;

        bool success;
        bytes memory err;
        if (opType == OperationType.Stake) {
            (success, err) = _simulateStake(user, amount);
        } else if (opType == OperationType.Withdraw) {
            (success, err) = _simulateWithdraw(user, amount);
        } else {
            (success, err) = _simulateClaim(user);
        }

        require(success, string(abi.encodePacked(_operationName(opType), " failed: ", err)));
    }

    /// @dev Verifies that a valid stake operation can be executed
    /// @param user The user address to simulate the stake operation
    /// @param amount The amount to stake

    function _verifyNoOverflow(uint256 value, string memory message) internal pure {
        require(value <= type(uint128).max, message);
    }

    // ─────────────────────────────────────────────────────────────
    // Simulation Helpers (State-preserving)
    // ─────────────────────────────────────────────────────────────

    function _simulateStake(address user, uint256 amount) internal view returns (bool, bytes memory) {
        try this.simulateExternalStake(user, amount) {
            return (true, "");
        } catch Error(string memory reason) {
            return (false, bytes(reason));
        } catch (bytes memory lowLevelData) {
            return (false, lowLevelData);
        }
    }

    /// @dev Simulates a stake operation without modifying state
    /// @param user The user address to simulate the stake operation
    /// @param amount The amount to stake

    function _selectUserWithBalance(OperationType opType) internal view returns (address) {
        for (uint256 i = 0; i < actors.length; i++) {
            address user = actors[i];
            if (opType == OperationType.Stake && stakingToken.balanceOf(user) > 0) {
                return user;
            }
            if (opType == OperationType.Withdraw && staking.balanceOf(user) > 0) {
                return user;
            }
            if (opType == OperationType.Claim && staking.earned(user) > 0) {
                return user;
            }
        }
        return address(0);
    }

    function _getValidStakeAmount(address user) internal view returns (uint256) {
        uint256 balance = stakingToken.balanceOf(user);
        uint256 allowance = stakingToken.allowance(user, address(staking));
        return balance > 0 && allowance > 0 ? _min(balance, allowance) : 0;
    }

    function _getValidWithdrawAmount(address user) internal view returns (uint256) {
        uint256 staked = staking.balanceOf(user);
        uint256 vaultBalance = stakingToken.balanceOf(address(staking));
        return staked > 0 && vaultBalance > 0 ? _min(staked, vaultBalance) : 0;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Safety Calculations                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _safeRewardRateBound() internal view returns (uint256) {
        uint256 maxRate = type(uint256).max / (365 days * 10);
        return maxRate > 0 ? maxRate : type(uint256).max;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Constants & Utilities                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _operationName(OperationType opType) private pure returns (string memory) {
        if (opType == OperationType.Stake) return "Stake";
        if (opType == OperationType.Withdraw) return "Withdraw";
        return "Claim";
    }
}
