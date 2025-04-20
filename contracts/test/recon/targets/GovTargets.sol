// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "../../../src/Gov.sol";

abstract contract GovTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory, /*ids*/
        uint256[] memory, /*amounts*/
        bytes memory data
    ) external returns (bytes4) {
        uint256[] memory testIds = new uint256[](1);
        uint256[] memory testAmounts = new uint256[](1);
        testIds[0] = 0;
        testAmounts[0] = 0;

        return gov.onERC1155BatchReceived(operator, from, testIds, testAmounts, data);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function gov_cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public asActor {
        gov.cancel(targets, values, calldatas, descriptionHash);
    }

    function gov_castVote(uint256 proposalId, uint8 support) public asActor {
        gov.castVote(proposalId, support);
    }

    function gov_castVoteBySig(
        uint256 proposalId,
        uint8 support,
        address voter,
        bytes memory signature
    ) public asActor {
        gov.castVoteBySig(proposalId, support, voter, signature);
    }

    function gov_castVoteWithReason(uint256 proposalId, uint8 support, string memory reason) public asActor {
        gov.castVoteWithReason(proposalId, support, reason);
    }

    function gov_castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string memory reason,
        bytes memory params
    ) public asActor {
        gov.castVoteWithReasonAndParams(proposalId, support, reason, params);
    }

    function gov_castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        address voter,
        string memory reason,
        bytes memory params,
        bytes memory signature
    ) public asActor {
        gov.castVoteWithReasonAndParamsBySig(proposalId, support, voter, reason, params, signature);
    }

    function gov_execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable asActor {
        gov.execute{value: msg.value}(targets, values, calldatas, descriptionHash);
    }

    function gov_onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public asActor {
        // Create proper arrays instead of using literals
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 0;
        amounts[0] = 0;

        gov.onERC1155BatchReceived(address(0), address(0), ids, amounts, bytes(""));
    }

    function gov_onERC1155Received(address, address, uint256, uint256, bytes memory) public asActor {
        gov.onERC1155Received(address(0), address(0), 0, 0, bytes(""));
    }

    function gov_onERC721Received(address, address, uint256, bytes memory) public asActor {
        gov.onERC721Received(address(0), address(0), 0, bytes(""));
    }

    function gov_propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public asActor {
        gov.propose(targets, values, calldatas, description);
    }

    function gov_queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public asActor {
        gov.queue(targets, values, calldatas, descriptionHash);
    }

    function gov_relay(address target, uint256 value, bytes memory data) public payable asActor {
        gov.relay{value: msg.value}(target, value, data);
    }

    function gov_setProposalThreshold(
        uint256 newProposalThreshold
    ) public asActor {
        gov.setProposalThreshold(newProposalThreshold);
    }

    function gov_setVotingDelay(
        uint48 newVotingDelay
    ) public asActor {
        gov.setVotingDelay(newVotingDelay);
    }

    function gov_setVotingPeriod(
        uint32 newVotingPeriod
    ) public asActor {
        gov.setVotingPeriod(newVotingPeriod);
    }

    function gov_updateQuorumNumerator(
        uint256 newQuorumNumerator
    ) public asActor {
        gov.updateQuorumNumerator(newQuorumNumerator);
    }

    function gov_updateTimelock(
        TimelockController newTimelock
    ) public asActor {
        gov.updateTimelock(newTimelock);
    }
}
