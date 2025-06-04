// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {E2E} from "./E2E.sol";
import {Staker} from "../../src/Staker.sol";

// forge test --match-test test_claimRewards_0 -vvv

contract CryticToFoundry is Test {
    E2E e2e;

    function setUp() public {
        e2e = new E2E();
    }

}
