// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() external returns (Counter) {
        vm.startBroadcast();
        Counter counter = new Counter();
        console.log("Counter deployed to:", address(counter));
        vm.stopBroadcast();

        return counter;
    }
}

// forge script script/Counter.s.sol --rpc-url  127.0.0.1:8545 --broadcast --verify --slow

// forge script script/Counter.s.sol --rpc-url 127.0.0.1:8545 --broadcast --private-key 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6 --verify --slow
