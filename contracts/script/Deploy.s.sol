// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/StakingToken.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() external returns (StakingToken) {
        vm.startBroadcast();

        string memory name = "StakeToken";
        string memory symbol = "STK";
        address initialOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; 

        StakingToken stakingtoken = new StakingToken(name, symbol, initialOwner);
        console.log("StakingToken deployed to:", address(stakingtoken));

        vm.stopBroadcast();

        return stakingtoken;
    }
}

// cast send 0xbdEd0D2bf404bdcBa897a74E6657f1f12e5C6fb6 "mint(address,uint256)" <recipient> 1000000000000000000000 --private-key 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba

// forge script script/Deploy.s.sol --rpc-url 127.0.0.1:8545 --broadcast --private-key 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
