// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "test/InvariantTests/MockVotesToken.sol";

abstract contract MockVotesTokenTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function mockVotesToken_approve(address spender, uint256 value) public asActor {
        mockVotesToken.approve(spender, value);
    }

    function mockVotesToken_delegate(
        address delegatee
    ) public asActor {
        mockVotesToken.delegate(delegatee);
    }

    function mockVotesToken_transfer(address to, uint256 value) public asActor {
        mockVotesToken.transfer(to, value);
    }

    function mockVotesToken_transferFrom(address from, address to, uint256 value) public asActor {
        mockVotesToken.transferFrom(from, to, value);
    }
}
