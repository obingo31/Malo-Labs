// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
import {vm} from "@chimera/Hevm.sol";
import {MALGovernanceStaking} from "../../../src/MALGovernanceStaking.sol";

abstract contract AdminTargets is BaseTargetFunctions, Properties {
    // Example admin function: update the voting period via the MALGovernanceStaking contract.
    // Usage: Instead of a plain public function, we use public updateGhosts asAdmin so that state
    // is captured correctly and the prank (msg.sender) is set as admin.
    function updateVotingPeriod_asAdmin(uint256 newVotingPeriod) public updateGhosts asAdmin {
        malGovernanceStaking.updateVotingPeriod(newVotingPeriod);
    }

    // You can add more admin target functions here.
    // For example, updating quorum or setting withdrawal cooldown:
    function updateQuorum_asAdmin(uint256 newQuorum) public updateGhosts asAdmin {
        malGovernanceStaking.updateQuorum(newQuorum);
    }

    function setWithdrawalCooldown_asAdmin(uint256 newCooldown) public updateGhosts asAdmin {
        malGovernanceStaking.setWithdrawalCooldown(newCooldown);
    }
}
