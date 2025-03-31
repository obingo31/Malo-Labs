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
}
