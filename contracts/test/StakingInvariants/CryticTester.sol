// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {CryticAsserts} from "@chimera/CryticAsserts.sol";

import {TargetFunctions} from "./TargetFunctions.sol";

// medusa fuzz
// echidna . --contract StakingCryticTester --config ./test/StakingInvariants/echidna.yaml --format text --workers 16 --test-limit 1000000

contract StakingCryticTester is TargetFunctions, CryticAsserts {
    constructor() payable {
        setup();
    }
}
