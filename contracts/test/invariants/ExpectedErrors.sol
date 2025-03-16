// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IAccessControl} from "@openzeppelin/contracts/interfaces/IAccessControl.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Properties} from "./Properties.sol";
import {Errors} from "./Errors.sol";

abstract contract ExpectedErrors is Properties {
    struct ErrorCategory {
        bytes4[] selectors;
        string name;
    }

    mapping(bytes32 => ErrorCategory) private _errorCategories;

    // Common error selectors
    bytes4 public constant INSUFFICIENT_BALANCE = IERC20Errors.ERC20InsufficientBalance.selector;
    bytes4 public constant UNAUTHORIZED = IAccessControl.AccessControlUnauthorizedAccount.selector;

    constructor() {
        _addCategory("Stake", _getStakeErrors());
        _addCategory("Withdraw", _getWithdrawErrors());
        _addCategory("ClaimRewards", _getClaimErrors());
        _addCategory("EmergencyWithdraw", _getEmergencyErrors());
        _addCategory("SetRewardRate", _getRewardRateErrors());
    }

    function _getStakeErrors() private pure returns (bytes4[] memory) {
        return [
            Errors.ZeroAmount.selector,
            INSUFFICIENT_BALANCE,
            Errors.InsufficientAllowance.selector,
            Errors.ContractPaused.selector,
            UNAUTHORIZED
        ];
    }

    function _getWithdrawErrors() private pure returns (bytes4[] memory) {
        return [
            Errors.ZeroAmount.selector,
            INSUFFICIENT_BALANCE,
            Errors.ContractPaused.selector,
            Errors.InsufficientBalance.selector
        ];
    }

    function _getClaimErrors() private pure returns (bytes4[] memory) {
        return [
            Errors.NoRewardsAvailable.selector,
            Errors.ClaimLockActive.selector,
            Errors.MaxDailyClaimExceeded.selector,
            Errors.ContractPaused.selector
        ];
    }

    function _getEmergencyErrors() private pure returns (bytes4[] memory) {
        return [Errors.NoStakedBalance.selector, Errors.ContractNotPaused.selector, Errors.EmergencyLockActive.selector];
    }

    function _getRewardRateErrors() private pure returns (bytes4[] memory) {
        return [
            Errors.ActiveRewardsPeriod.selector,
            Errors.RewardRateTooHigh.selector,
            Errors.InsufficientRewardTokens.selector,
            UNAUTHORIZED
        ];
    }

    function _addCategory(string memory name, bytes4[] memory selectors) internal {
        bytes32 categoryHash = keccak256(abi.encodePacked(name));
        _errorCategories[categoryHash] = ErrorCategory(selectors, name);
    }

    function checkExpectedErrors(string memory category) internal view {
        bytes32 categoryHash = keccak256(abi.encodePacked(category));
        require(_errorCategories[categoryHash].selectors.length > 0, "Invalid error category");
    }

    function executeWithValidation(address target, bytes memory data, string memory category)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory result) = target.call(data);
        if (!success) {
            bytes4 errSelector = _parseErrorSelector(result);
            require(_isErrorInCategory(errSelector, category), _buildErrorMessage(category, errSelector));
        }
        return result;
    }

    function _isErrorInCategory(bytes4 selector, string memory category) internal view returns (bool) {
        bytes32 categoryHash = keccak256(abi.encodePacked(category));
        return _isErrorRegistered(selector, _errorCategories[categoryHash].selectors);
    }

    function _isErrorRegistered(bytes4 selector, bytes4[] storage registered) internal view returns (bool) {
        for (uint256 i = 0; i < registered.length; i++) {
            if (selector == registered[i]) return true;
        }
        return false;
    }

    function _parseErrorSelector(bytes memory data) internal pure returns (bytes4) {
        return data.length >= 4 ? bytes4(data) : bytes4(0);
    }

    function _buildErrorMessage(string memory category, bytes4 selector) internal pure returns (string memory) {
        return string(abi.encodePacked("Unexpected error in ", category, ": 0x", _bytes4ToHex(selector)));
    }

    function _bytes4ToHex(bytes4 selector) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789ABCDEF";
        bytes memory result = new bytes(8);

        for (uint256 i = 0; i < 4; i++) {
            result[i * 2] = hexChars[uint8(selector[i] >> 4)];
            result[i * 2 + 1] = hexChars[uint8(selector[i] & 0x0f)];
        }
        return string(result);
    }
}