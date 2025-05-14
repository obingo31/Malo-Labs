// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/StakingToken.sol";

contract DeployScript is Script {
    address public constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {}

    function run() external returns (StakingToken) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        string memory name = "StakeToken";
        string memory symbol = "STK";
        address initialOwner = DEPLOYER;

        StakingToken stakingtoken = new StakingToken(name, symbol, initialOwner);
        console.log("StakingToken deployed to:", address(stakingtoken));

        vm.stopBroadcast();

        return stakingtoken;
    }
}
