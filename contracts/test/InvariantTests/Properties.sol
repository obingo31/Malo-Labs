// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {
    address[] public actors;

    // Example invariant test
    function invariant_rewardRate_nonzero() public {
        gt(malGovernanceStaking.rewardRate(), 0, "reward rate is zero");
    }

    /// @dev Voting power MUST reset to zero after full withdrawal
    /// @return bool Returns true if property holds, false otherwise
    function property_full_withdrawal_resets_voting_power() public view returns (bool) {
        // Skip non-withdrawal operations
        if (currentOperation != OpType.WITHDRAW) return true;
        
        address user = _currentActor();
        
        // Skip partial withdrawals
        if (_after.userStakes[user] != 0) return true;

        // Actual check
        return malGovernanceStaking.getVotingPower(user) == 0;
    }

    /// @dev Total staked must match sum of individual stakes
    function invariant_staking_balance_consistency() public {
        uint256 total = malGovernanceStaking.totalStaked();
        uint256 sum = 0;
        
        for (uint256 i = 0; i < actors.length; i++) {
            sum += malGovernanceStaking.stakedBalance(actors[i]);
        }
        
        eq(total, sum, "Total staked mismatch");
    }

    /// @dev Proposals should never exceed lifetime without cleanup
    function property_proposal_expiration() public view returns (bool) {
        uint256 count = malGovernanceStaking.proposalCount();
        
        for (uint256 i = 1; i <= count; i++) {
            (, , , , , uint256 endTime, , bool executed, bool expired) = 
                malGovernanceStaking.proposals(i);
            
            if (block.timestamp > endTime + malGovernanceStaking.proposalLifetime()) {
                if (!expired && !executed) return false;
            }
        }
        return true;
    }
}