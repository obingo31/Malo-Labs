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
import {GovTokenTargets} from "./targets/GovTokenTargets.sol";
import {ManagersTargets} from "./targets/ManagersTargets.sol";

abstract contract TargetFunctions is AdminTargets, DoomsdayTargets, GovTokenTargets, ManagersTargets {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function mALGovernanceStaking_claimRewards() public asActor {
        mALGovernanceStaking.claimRewards();
    }

    function mALGovernanceStaking_cleanExpiredProposals() public asActor {
        mALGovernanceStaking.cleanExpiredProposals();
    }

    function mALGovernanceStaking_createProposal(address target, bytes memory data) public asActor {
        mALGovernanceStaking.createProposal(target, data);
    }

    function mALGovernanceStaking_executeProposal(
        uint256 proposalId
    ) public asActor {
        mALGovernanceStaking.executeProposal(proposalId);
    }

    function mALGovernanceStaking_grantRole(bytes32 role, address account) public asActor {
        mALGovernanceStaking.grantRole(role, account);
    }

    function mALGovernanceStaking_renounceRole(bytes32 role, address callerConfirmation) public asActor {
        mALGovernanceStaking.renounceRole(role, callerConfirmation);
    }

    function mALGovernanceStaking_revokeRole(bytes32 role, address account) public asActor {
        mALGovernanceStaking.revokeRole(role, account);
    }

    function mALGovernanceStaking_setWithdrawalCooldown(
        uint256 newCooldown
    ) public asActor {
        mALGovernanceStaking.setWithdrawalCooldown(newCooldown);
    }

    function mALGovernanceStaking_stake(
        uint256 amount
    ) public asActor {
        mALGovernanceStaking.stake(amount);
    }

    function mALGovernanceStaking_updateQuorum(
        uint256 newPercentage
    ) public asActor {
        mALGovernanceStaking.updateQuorum(newPercentage);
    }

    function mALGovernanceStaking_updateVotingPeriod(
        uint256 newPeriod
    ) public asActor {
        mALGovernanceStaking.updateVotingPeriod(newPeriod);
    }

    function mALGovernanceStaking_vote(uint256 proposalId, bool support) public asActor {
        mALGovernanceStaking.vote(proposalId, support);
    }

    function mALGovernanceStaking_withdraw(
        uint256 amount
    ) public asActor {
        mALGovernanceStaking.withdraw(amount);
    }
}
