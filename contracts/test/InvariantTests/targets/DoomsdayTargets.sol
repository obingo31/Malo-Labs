// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
import {vm} from "@chimera/Hevm.sol";
import {MALGovernanceStaking} from "../../../src/MALGovernanceStaking.sol";

abstract contract DoomsdayTargets is BaseTargetFunctions, Properties {
    /// Makes a handler have no side effects.
    /// The fuzzer will call this anyway, and because it reverts it will be removed from shrinking.
    /// Use the stateless modifier to ensure that after execution the state reverts.
    modifier stateless() {
        _;
        revert("stateless");
    }

    /// Example doomsday function: Ensure that updating the voting period never reverts.
    /// This function is executed as an admin, and the state is captured before and after via our ghost system.
    function doomsday_updateVotingPeriod_never_reverts(
        uint256 newVotingPeriod
    ) public stateless asAdmin {
        try malGovernanceStaking.updateVotingPeriod(newVotingPeriod) {
            // If the update succeeds, nothing further is done.
        } catch {
            // If the call reverts, flag the error.
            t(false, "doomsday_updateVotingPeriod_never_reverts");
        }
    }
}
