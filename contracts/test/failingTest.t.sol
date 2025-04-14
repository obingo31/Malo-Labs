// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {DepositContract} from "./DepositContract.sol";

contract DepositContractTest is Test {
    DepositContract depositContract;

    function setUp() public {
        depositContract = new DepositContract();
    }

    function testMultipleNonceIncrements() public {
        address user = makeAddr("multi-nonce-user");
        vm.deal(user, 10 ether);

        // First transaction
        vm.startBroadcast(user);
        depositContract.deposit{value: 1 ether}();
        vm.stopBroadcast();

        // Second transaction
        vm.startBroadcast(user);
        depositContract.deposit{value: 1 ether}();
        vm.stopBroadcast();

        // Verify nonce incremented twice
        assertEq(vm.getNonce(user), 2, "Nonce should be 2 after 2 txs");
    }

    function testNonceIncrement() public {
        address user = makeAddr("nonce-test-user");
        vm.deal(user, 10 ether);

        vm.startBroadcast(user);
        depositContract.deposit{value: 1 ether}();
        vm.stopBroadcast();

        assertEq(vm.getNonce(user), 1, "Nonce should increment after tx");
    }
}
