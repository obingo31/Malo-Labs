// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/GovToken.sol";

abstract contract GovTokenTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function govToken_approve(address spender, uint256 value) public asActor {
        govToken.approve(spender, value);
    }

    function govToken_delegate(
        address delegatee
    ) public asActor {
        govToken.delegate(delegatee);
    }

    function govToken_delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public asActor {
        govToken.delegateBySig(delegatee, nonce, expiry, v, r, s);
    }

    function govToken_mint(address account, uint256 amount) public asActor {
        govToken.mint(account, amount);
    }

    function govToken_permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public asActor {
        govToken.permit(owner, spender, value, deadline, v, r, s);
    }

    function govToken_transfer(address to, uint256 value) public asActor {
        govToken.transfer(to, value);
    }

    function govToken_transferFrom(address from, address to, uint256 value) public asActor {
        govToken.transferFrom(from, to, value);
    }
}
