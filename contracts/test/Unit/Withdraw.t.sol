// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

// import "forge-std/src/Test.sol";

// import {Staker} from "src/Staker.sol";
// import {ERC20} from "solmate/src/tokens/ERC20.sol";

// import {Errors} from "src/Errors.sol";

// contract WithdrawTest is  {
//     function setUp() public override {

//     }

//     function test_Withdraw(uint48 timeJump) public {

//         Init memory init = Init({
//             user: [alice, bob, makeAddr("shikanoko"), makeAddr("koshitan")],

//         });

//          //TODO:

//         _test_Withdraw(init, shares, timeJump);
//     }

//     function testFuzz_Withdraw()
//        // TODO: add boundInit(init)

//     }

//     function _test_Withdraw() internal {

//      //TODO
//         address owner = init.user[0];
//         address receiver = init.user[1];
//         address caller = init.user[2];

//         vm.warp();

//         assertEq(, , "Withdraw should ...");
//     }

//     function test_RevertWhen_NotExpired() public {
//         vm.expectRevert(Errors.NotExpired.selector);
//         vm.warp(expiry - 1);
//         staker.withdraw(100, alice, alice);
//     }

//     error InsufficientAllowance();

//     function test_RevertWhen_NotApproved() public {
//         _approve(staker, alice, bob, 99);
//         vm.warp(expiry);

//         vm.expectRevert(InsufficientAllowance.selector);
//         vm.prank(alice);
//         principalToken.withdraw(100, alice, bob);
//     }
// }
