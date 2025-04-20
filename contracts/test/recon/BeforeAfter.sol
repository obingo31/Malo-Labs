// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";
import {Asserts} from "@chimera/Asserts.sol";
import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";

abstract contract BeforeAfter is Setup, Asserts {
    struct Vars {
        mapping(uint256 => Governor.ProposalState) proposalStates;
        mapping(address => uint256) tokenBalances;
        mapping(address => uint256) votingPowers;
    }

    Vars internal _before;
    Vars internal _after;

    // Actors must be set once in your test setup via `setActors(...)`
    address[] internal _actors;

    modifier withChecks() {
        __before();
        _;
        __after();
    }

    function __before() internal {
        _trackProposalStates(_before);
        for (uint256 i = 0; i < _actors.length; i++) {
            address actor = _actors[i];
            _before.tokenBalances[actor] = govToken.balanceOf(actor);
            _before.votingPowers[actor] = govToken.getVotes(actor);
        }
    }

    function __after() internal {
        _trackProposalStates(_after);
        for (uint256 i = 0; i < _actors.length; i++) {
            address actor = _actors[i];
            _after.tokenBalances[actor] = govToken.balanceOf(actor);
            _after.votingPowers[actor] = govToken.getVotes(actor);
        }
    }

    function _trackProposalStates(
        Vars storage vars
    ) private {
        // Scan proposals 1–100; Governor.state() reverts beyond the last proposal :contentReference[oaicite:2]{index=2}
        for (uint256 id = 1; id <= 100; id++) {
            try gov.state(id) returns (Governor.ProposalState st) {
                vars.proposalStates[id] = st;
            } catch {
                break;
            }
        }
    }

    /// @notice Define which addresses to snapshot
    function setActors(
        address[] memory actors_
    ) internal {
        _actors = actors_;
    }
}
