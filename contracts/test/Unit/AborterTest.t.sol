// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../simulation/Aborter.sol";

contract AborterTest is Test {
    Staking staking;
    Aborter aborter;

    address user = address(0x123);
    uint256 stakeAmount = 100e18;

    function setUp() public {
        // Deploy the Aborter contract as our fake staking token.
        aborter = new Aborter("Stake failed", true);
        staking = new Staking(address(aborter), address(0x456), address(this), 1 weeks, address(this));
    }

    function testStakeReverts() public {
        vm.prank(user);
        vm.expectRevert("Stake failed");
        staking.stake(stakeAmount);
    }
}

// forge test --match-test testStakeReverts
