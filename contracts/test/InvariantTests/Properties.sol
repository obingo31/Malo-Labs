// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {
    // Example property test that gets called randomly by the fuzzer:
    // Ensure that the reward rate is always greater than zero.
    function invariant_rewardRate_nonzero() public {
        gt(malGovernanceStaking.rewardRate(), 0, "reward rate is zero");
    }

    /// @dev Delegation MUST reset to zero after full withdrawal
    /// @return bool Returns true if the property holds, false otherwise
    function property_full_withdrawal_resets_delegation() public view returns (bool) {
        // Skip check if not a withdrawal operation
        if (currentOperation != OpType.WITHDRAW) return true;

        // Skip check if user still has stakes
        if (_after.userStakes[_currentActor()] != 0) return true;

        // Verify voting power is reset to 0 after full withdrawal
        bool isValid = malGovernanceStaking.getVotingPower(_currentActor()) == 0;
        require(isValid, "Delegation not reset after full withdrawal");
        return true;
    }
}
