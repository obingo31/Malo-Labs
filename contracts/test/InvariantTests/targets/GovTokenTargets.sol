// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import {GovToken} from "../../../src/GovToken.sol";

abstract contract GovTokenTargets is BaseTargetFunctions, Properties {
    GovToken public govToken;

    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    function govToken_mint(address to, uint256 amount) public asActor {
        try govToken.mint(to, amount) {
            // Mint successful
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function govToken_transfer(address to, uint256 amount) public asActor {
        try govToken.transfer(to, amount) returns (bool success) {
            require(success, "GovToken: transfer failed");
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function govToken_approve(address spender, uint256 amount) public asActor {
        try govToken.approve(spender, amount) returns (bool success) {
            require(success, "GovToken: approve failed");
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function govToken_transferFrom(address from, address to, uint256 amount) public asActor {
        try govToken.transferFrom(from, to, amount) returns (bool success) {
            require(success, "GovToken: transferFrom failed");
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function govToken_delegate(
        address delegatee
    ) public asActor {
        try govToken.delegate(delegatee) {
            // Delegation successful
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function govToken_delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public asActor {
        try govToken.delegateBySig(delegatee, nonce, expiry, v, r, s) {
            // Delegation successful
        } catch Error(string memory reason) {
            revert(reason);
        }
    }
}
