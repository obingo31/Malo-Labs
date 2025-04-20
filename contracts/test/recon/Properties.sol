// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter {
    /// @dev Critical: Total voting power must always equal token supply
    function property_voting_power_supply_match() public view returns (bool) {
        uint256 totalSupply = govToken.totalSupply();
        uint256 totalVotes = govToken.getPastTotalSupply(block.number - 1);
        return totalSupply == totalVotes;
    }

    /// @dev Critical: Voting power should never exceed token balance
    function property_no_sybil_attacks() public view returns (bool) {
        address actor = _getActor();
        return govToken.getPastVotes(actor, block.number - 1) <= govToken.balanceOf(actor);
    }
}
