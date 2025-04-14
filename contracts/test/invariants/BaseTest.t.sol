// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StdAsserts} from "./StdAsserts.sol";
import {BaseStorage} from "./BaseStorage.t.sol";
import {Actor} from "./Actor.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseTest is BaseStorage, StdAsserts {
    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                   ACTOR PROXY MECHANISM                                   //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    modifier setup() virtual {
        activeActor = actors[msg.sender];
        _;
        activeActor = Actor(payable(address(0)));
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                     CHEAT CODE SETUP                                      //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                       TEST HELPERS                                        //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    function _getStakedBalance(address user) internal view returns (uint256) {
        return staker.stakedBalanceOf(user);
    }

    function _getEarnedRewards(address user, address rewardToken) internal view returns (uint256) {
        return staker.earned(user, rewardToken);
    }

    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return staker.hasRole(role, account);
    }

    function _advanceTime(uint256 duration) internal {
        vm.warp(block.timestamp + duration);
    }

    function _makeAddr(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encode(name)))));
    }

    function _getRandomActor(uint256 seed) internal view returns (address) {
        if (actorAddresses.length == 0) return address(0);
        uint256 actorIndex = seed % actorAddresses.length;
        return actorAddresses[actorIndex];
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                    ASSERTION HELPERS                                      //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    function _assertApproxEqual(uint256 a, uint256 b, uint256 delta) internal {
        assertApproxEqAbs(a, b, delta, "Value mismatch within delta");
    }

    function _assertRole(bytes32 role, address account) internal {
        assertTrue(staker.hasRole(role, account), "Role mismatch");
    }

    function _assertBalanceEq(address token, address account, uint256 expected) internal {
        assertEq(IERC20(token).balanceOf(account), expected, "Token balance mismatch");
    }
}
