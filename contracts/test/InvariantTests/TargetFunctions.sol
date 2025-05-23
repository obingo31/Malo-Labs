// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
// import {vm} from "@chimera/Hevm.sol";
import {IHevm, vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

// Targets
// NOTE: Always import and apply them in alphabetical order, so much easier to debug!
import {AdminTargets} from "./targets/AdminTargets.sol";
import {DoomsdayTargets} from "./targets/DoomsdayTargets.sol";
import {ManagersTargets} from "./targets/ManagersTargets.sol";

abstract contract TargetFunctions is AdminTargets, DoomsdayTargets, ManagersTargets {
    function staking_stake() public updateGhosts asActor {
        malGovernanceStaking.stake(1e18);
    }

    ///@dev If newVotingPeriod is nonzero, assert that the voting period was updated.
    function staking_updateVotingPeriod1(
        uint256 newVotingPeriod
    ) public updateGhosts asAdmin {
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

    function staking_updateVotingPeriod2(
        uint256 newVotingPeriod
    ) public updateGhosts asAdmin {
        __before();

        malGovernanceStaking.updateVotingPeriod(newVotingPeriod);

        __after();

        if (newVotingPeriod != 0) {
            t(_after.votingPeriod == newVotingPeriod, "votingPeriod mismatch");
        }
    }

    function handler_updateQuorum(
        uint256 newPercentage
    ) external updateGhosts asAdmin {
        vm.assume(newPercentage <= 100);

        try malGovernanceStaking.updateQuorum(newPercentage) {
            t(malGovernanceStaking.quorumPercentage() == newPercentage, "Quorum update failed");
        } catch {
            t(false, "Unexpected revert");
        }
    }

    ///////////////////////////////////////////////////////////////
    // Governance Functions
    ///////////////////////////////////////////////////////////////

    function handler_createProposal(address target, bytes calldata data) external updateGhosts asActor {
        address actor = _currentActor();
        vm.assume(malGovernanceStaking.getVotingPower(actor) >= malGovernanceStaking.proposalThreshold());

        malGovernanceStaking.createProposal(target, data);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function mALGovernanceStaking_claimRewards() public asActor {
        malGovernanceStaking.claimRewards();
    }

    function mALGovernanceStaking_cleanExpiredProposals() public asActor {
        malGovernanceStaking.cleanExpiredProposals();
    }

    function mALGovernanceStaking_createProposal(address target, bytes memory data) public asActor {
        malGovernanceStaking.createProposal(target, data);
    }

    function mALGovernanceStaking_executeProposal(
        uint256 proposalId
    ) public asActor {
        malGovernanceStaking.executeProposal(proposalId);
    }

    function mALGovernanceStaking_grantRole(bytes32 role, address account) public asActor {
        malGovernanceStaking.grantRole(role, account);
    }

    function mALGovernanceStaking_renounceRole(bytes32 role, address callerConfirmation) public asActor {
        malGovernanceStaking.renounceRole(role, callerConfirmation);
    }

    function mALGovernanceStaking_revokeRole(bytes32 role, address account) public asActor {
        malGovernanceStaking.revokeRole(role, account);
    }

    function mALGovernanceStaking_setWithdrawalCooldown(
        uint256 newCooldown
    ) public asActor {
        malGovernanceStaking.setWithdrawalCooldown(newCooldown);
    }

    function mALGovernanceStaking_stake(
        uint256 amount
    ) public asActor {
        malGovernanceStaking.stake(amount);
    }

    function mALGovernanceStaking_updateQuorum(
        uint256 newPercentage
    ) public asActor {
        malGovernanceStaking.updateQuorum(newPercentage);
    }

    function mALGovernanceStaking_updateVotingPeriod(
        uint256 newPeriod
    ) public asActor {
        malGovernanceStaking.updateVotingPeriod(newPeriod);
    }

    function mALGovernanceStaking_vote(uint256 proposalId, bool support) public asActor {
        malGovernanceStaking.vote(proposalId, support);
    }

    function mALGovernanceStaking_withdraw(
        uint256 amount
    ) public asActor {
        malGovernanceStaking.withdraw(amount);
    }
}
