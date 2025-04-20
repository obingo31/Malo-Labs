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
import {GovTargets} from "./targets/GovTargets.sol";
import {GovTokenTargets} from "./targets/GovTokenTargets.sol";
import {ManagersTargets} from "./targets/ManagersTargets.sol";
import {MockVotesTokenTargets} from "./targets/MockVotesTokenTargets.sol";

abstract contract TargetFunctions is
    AdminTargets,
    DoomsdayTargets,
    GovTargets,
    GovTokenTargets,
    ManagersTargets,
    MockVotesTokenTargets
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///
    /// @dev Handler for creating a proposal
    function handler_propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public {
        // Preconditions: non-empty, matching lengths
        if (targets.length == 0) return;
        if (targets.length != values.length || values.length != calldatas.length) return;
        gov.propose(targets, values, calldatas, description);
    }

    

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
}
