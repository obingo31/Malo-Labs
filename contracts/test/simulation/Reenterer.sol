// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import {Vm} from "forge-std/Vm.sol";

// contract Reenterer {
//     // Vm private constant cheats = Vm(VM_ADDRESS);

//     address public target;
//     uint256 public msgValue;
//     bytes public callData;
//     bytes public expectedRevert;
//     uint256 public maxDepth;
//     uint256 public currentDepth;

//     event Reentered(bytes data);

//     function prepare(
//         address _target,
//         uint256 _value,
//         bytes calldata _callData,
//         bytes memory _expectedRevert,
//         uint256 _maxDepth
//     ) external {
//         target = _target;
//         msgValue = _value;
//         callData = _callData;
//         expectedRevert = _expectedRevert;
//         maxDepth = _maxDepth;
//         currentDepth = 0;
//     }

//     receive() external payable {
//         if (currentDepth >= maxDepth) return;
//         currentDepth++;

//         if (expectedRevert.length > 0) {
//             cheats.expectRevert(expectedRevert);
//         }

//         (bool success, bytes memory data) = target.call{value: msgValue}(callData);
//         if (!success) {
//             assembly {
//                 returndatacopy(0, 0, returndatasize())
//                 revert(0, returndatasize())
//             }
//         }
//         emit Reentered(data);
//     }
// }
