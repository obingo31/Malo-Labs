// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

// Targets
// NOTE: Always import and apply them in alphabetical order, so much easier to debug!
import {AdminTargets} from "./targets/AdminTargets.sol";
import {DoomsdayTargets} from "./targets/DoomsdayTargets.sol";
import {ManagersTargets} from "./targets/ManagersTargets.sol";

abstract contract TargetFunctions is AdminTargets, DoomsdayTargets, ManagersTargets {
    /// Example function: Stake a fixed amount (e.g. 1e18 tokens) as an actor.
    function staking_stake() public updateGhosts asActor {
        // For testing purposes, stake 1e18 units.
        malGovernanceStaking.stake(1e18);
    }

    /// Test updating the voting period with try/catch.
    /// If newVotingPeriod is nonzero, assert that the voting period was updated.
    function staking_updateVotingPeriod1(uint256 newVotingPeriod) public updateGhosts asAdmin {
        try malGovernanceStaking.updateVotingPeriod(newVotingPeriod) {
            if (newVotingPeriod != 0) {
                t(malGovernanceStaking.votingPeriod() == newVotingPeriod, "votingPeriod mismatch");
            }
        } catch (bytes memory err) {
            bool expectedError;
            // Check for expected error strings or panics.
            expectedError = checkError(err, "InvalidVotingPeriod") || checkError(err, "CustomError()")
                || checkError(err, Panic.arithmeticPanic);
            t(expectedError, "unexpected error in updateVotingPeriod1");
        }
    }

    /// Test updating the voting period using ghost variables.
    /// Captures state before and after the call and asserts the expected change.
    function staking_updateVotingPeriod2(uint256 newVotingPeriod) public updateGhosts asAdmin {
        __before();

        malGovernanceStaking.updateVotingPeriod(newVotingPeriod);

        __after();

        if (newVotingPeriod != 0) {
            t(_after.votingPeriod == newVotingPeriod, "votingPeriod mismatch");
        }
    }
}
