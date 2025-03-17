// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
// import {Deploy} from "@script/Deploy.sol";
import {Errors} from "src/libraries/Errors.sol";
//import {Properties} from "./Properties.sol";

abstract contract ExpectedErrors {
    bool internal success;
    bytes internal returnData;

    bytes4[] internal DEPOSIT_ERRORS;
    bytes4[] internal WITHDRAW_ERRORS;
    bytes4[] internal STAKE_ERRORS;
    bytes4[] internal CLAIM_REWARD_ERRORS;
    bytes4[] internal EMERGENCY_WITHDRAW_ERRORS;
    bytes4[] internal SET_FEE_ERRORS;
    bytes4[] internal SET_REWARD_RATE_ERRORS;
    bytes4[] internal SET_REWARD_PERIOD_ERRORS;
    bytes4[] internal PAUSE_ERRORS;
    bytes4[] internal UNPAUSE_ERRORS;

    constructor() {
        // DEPOSIT_ERRORS
        DEPOSIT_ERRORS.push(IERC20Errors.ERC20InsufficientBalance.selector);
        DEPOSIT_ERRORS.push(Errors.INVALID_TOKEN.selector);
        DEPOSIT_ERRORS.push(Errors.NULL_AMOUNT.selector);
        DEPOSIT_ERRORS.push(Errors.NULL_ADDRESS.selector);

        // WITHDRAW_ERRORS
        WITHDRAW_ERRORS.push(IERC20Errors.ERC20InsufficientBalance.selector);
        WITHDRAW_ERRORS.push(Errors.NULL_AMOUNT.selector);
        WITHDRAW_ERRORS.push(Errors.WITHDRAW_AMOUNT_EXCEEDS_BALANCE.selector);

        // STAKE_ERRORS
        STAKE_ERRORS.push(Errors.NULL_AMOUNT.selector);
        STAKE_ERRORS.push(IERC20Errors.ERC20InsufficientBalance.selector);
        STAKE_ERRORS.push(Errors.TRANSFER_FAILED.selector);
        STAKE_ERRORS.push(Errors.STAKING_PAUSED.selector);

        // CLAIM_REWARD_ERRORS
        CLAIM_REWARD_ERRORS.push(Errors.NO_REWARDS_AVAILABLE.selector);
        CLAIM_REWARD_ERRORS.push(Errors.TRANSFER_FAILED.selector);
        CLAIM_REWARD_ERRORS.push(Errors.REWARDS_PERIOD_NOT_ENDED.selector);

        // EMERGENCY_WITHDRAW_ERRORS
        EMERGENCY_WITHDRAW_ERRORS.push(Errors.INSUFFICIENT_BALANCE.selector);
        EMERGENCY_WITHDRAW_ERRORS.push(Errors.TRANSFER_FAILED.selector);
        EMERGENCY_WITHDRAW_ERRORS.push(Errors.CONTRACT_PAUSED.selector);

        // SET_FEE_ERRORS
        SET_FEE_ERRORS.push(Errors.INVALID_FEE_AMOUNT.selector);
        SET_FEE_ERRORS.push(IAccessControl.AccessControlUnauthorizedAccount.selector);

        // SET_REWARD_RATE_ERRORS
        SET_REWARD_RATE_ERRORS.push(Errors.INVALID_REWARD_RATE.selector);
        SET_REWARD_RATE_ERRORS.push(Errors.INSUFFICIENT_BALANCE.selector);
        SET_REWARD_RATE_ERRORS.push(Errors.ACTIVE_REWARDS_PERIOD.selector);

        // SET_REWARD_PERIOD_ERRORS
        SET_REWARD_PERIOD_ERRORS.push(Errors.INVALID_REWARD_PERIOD.selector);
        SET_REWARD_PERIOD_ERRORS.push(Errors.ACTIVE_REWARDS_PERIOD.selector);

        // PAUSE_ERRORS
        PAUSE_ERRORS.push(IAccessControl.AccessControlUnauthorizedAccount.selector);
        PAUSE_ERRORS.push(Errors.ALREADY_PAUSED.selector);

        // UNPAUSE_ERRORS
        UNPAUSE_ERRORS.push(IAccessControl.AccessControlUnauthorizedAccount.selector);
        UNPAUSE_ERRORS.push(Errors.NOT_PAUSED.selector);
    }

    modifier checkExpectedErrors(bytes4[] storage errors) {
        success = false;
        returnData = bytes("");

        _;

        if (!success) {
            bool expected = false;
            for (uint256 i = 0; i < errors.length; i++) {
                if (errors[i] == bytes4(returnData)) {
                    expected = true;
                    break;
                }
            }
            require(expected, "Unexpected error encountered");
            // precondition(false);
        }
    }
}
