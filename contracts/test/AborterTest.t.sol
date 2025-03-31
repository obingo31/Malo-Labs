// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import the Staking and Aborter contracts.
import "forge-std/Test.sol";
import "src/Staking.sol";
import "./simulation/Aborter.sol";

contract AborterTest is Test {
    Staking staking;
    Aborter aborter;

    // Use an arbitrary user address (you could also use vm.addr(...) in Foundry)
    address user = address(0x123);
    // Amount to stake (nonzero so that the transfer is attempted)
    uint256 stakeAmount = 100e18;

    function setUp() public {
        // Deploy the Aborter contract as our fake staking token.
        // Set shouldAbort = true so that any call reverts with "Stake failed"
        aborter = new Aborter("Stake failed", true);

        // (Optionally, you can configure allowedSelector if you want to bypass abort on a specific function,
        // but here we leave it at zero so every call reverts.)

        // Deploy the Staking contract with the aborter as the stakingToken.
        // For simplicity, we use dummy addresses for _maloToken (reward token) since stake() doesn't interact with it.
        staking = new Staking(
            address(aborter), // stakingToken: our Aborter, which always reverts on transfer
            address(0x456), // _maloToken: dummy (not used in stake)
            address(this), // initialOwner
            1 weeks, // rewardPeriod
            address(this) // feeRecipient
        );

        // We assume that in our test scenario the user has enough token balance and has approved the staking contract.
        // (Since Aborter does not implement approve(), we are solely testing that stake() fails when the
        // transfer is attempted.)
    }

    function testStakeReverts() public {
        // Simulate the call coming from "user".
        vm.prank(user);
        // Expect the stake call to revert with the error message from Aborter.
        vm.expectRevert("Stake failed");
        staking.stake(stakeAmount);
    }
}
