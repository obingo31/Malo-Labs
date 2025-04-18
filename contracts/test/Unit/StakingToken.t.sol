// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StakingToken} from "../../src/StakingToken.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract StakingTokenTest is Test {
    StakingToken public token;
    address public owner;
    address public user;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        token = new StakingToken("StakeToken", "STK", owner);
    }

    function testMint() public {
        uint256 amount = 1000e18;
        vm.prank(owner);
        token.mint(user, amount);
        assertEq(token.balanceOf(user), amount);
    }

    function testMintNotOwner() public {
        uint256 amount = 1000e18;
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, amount);
    }
}
