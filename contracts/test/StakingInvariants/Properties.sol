// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {StakingPostconditions} from "./StakingPostconditions.sol";
import {StakingInvariants} from "./StakingInvariants.sol";

abstract contract Properties is BeforeAfter, Asserts, StakingPostconditions, StakingInvariants {
    // ███████╗████████╗ █████╗ ██╗  ██╗██╗███╗   ██╗ ██████╗ 
    // ██╔════╝╚══██╔══╝██╔══██╗██║ ██╔╝██║████╗  ██║██╔════╝ 
    // ███████╗   ██║   ███████║█████╔╝ ██║██╔██╗ ██║██║  ███╗
    // ╚════██║   ██║   ██╔══██║██╔═██╗ ██║██║╚██╗██║██║   ██║
    // ███████║   ██║   ██║  ██║██║  ██╗██║██║ ╚████║╚██████╔╝
    // ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 

    function invariant_CORE_INV_A() public  {
        uint256 totalBal;
        address[] memory actors = _getActors();
        for (uint i; i < actors.length; i++) {
            totalBal += staking.balanceOf(actors[i]);
        }
        eq(totalBal, staking.totalStaked(), CORE_INV_A);
    }

    // ██████╗ ███████╗██╗    ██╗ █████╗ ██████╗ ██████╗ 
    // ██╔══██╗██╔════╝██║    ██║██╔══██╗██╔══██╗██╔══██╗
    // ██████╔╝█████╗  ██║ █╗ ██║███████║██████╔╝██║  ██║
    // ██╔══██╗██╔══╝  ██║███╗██║██╔══██║██╔══██╗██║  ██║
    // ██║  ██║███████╗╚███╔███╔╝██║  ██║██║  ██║██████╔╝
    // ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 

    function invariant_REWARD_INV_A() public  {
        uint256 rewards = staking.totalRewardsDistributed();
        uint256 balance = staking.maloToken().balanceOf(address(staking));
        lte(rewards, balance, REWARD_INV_A);
    }

    // ██╗      ██████╗  ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗ 
    // ██║     ██╔═══██╗██╔════╝██║ ██╔╝██║████╗  ██║██╔════╝ 
    // ██║     ██║   ██║██║     █████╔╝ ██║██╔██╗ ██║██║  ███╗
    // ██║     ██║   ██║██║     ██╔═██╗ ██║██║╚██╗██║██║   ██║
    // ███████╗╚██████╔╝╚██████╗██║  ██╗██║██║ ╚████║╚██████╔╝
    // ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 

    function invariant_LOCK_INV_B() public {
        address[] memory actors = _getActors();
        for (uint i; i < actors.length; i++) {
            for (uint j; j < actors.length; j++) {
                (uint locked, uint allowance) = staking.getLock(actors[i], actors[j]);
                if (allowance > 0) {
                    lte(locked, allowance, LOCK_INV_B);
                }
            }
        }
    }

    // ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
    // ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
    //    ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
    //    ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
    //    ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
    //    ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝

    function invariant_TOKEN_GPOST_A() public  {
        uint onChain = staking.stakingToken().balanceOf(address(staking));
        eq(onChain, staking.totalStaked(), TOKEN_GPOST_A);
    }

    // ███████╗███╗   ███╗███████╗███████╗██████╗ ██████╗ ██╗   ██╗
    // ██╔════╝████╗ ████║██╔════╝██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
    // █████╗  ██╔████╔██║█████╗  █████╗  ██████╔╝██████╔╝ ╚████╔╝ 
    // ██╔══╝  ██║╚██╔╝██║██╔══╝  ██╔══╝  ██╔══██╗██╔══██╗  ╚██╔╝  
    // ███████╗██║ ╚═╝ ██║███████╗███████╗██║  ██║██║  ██║   ██║   
    // ╚══════╝╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   

    function invariant_EMERG_INV_A() public  {
        if (staking.paused()) {
            gt(staking.balanceOf(address(this)), 0, EMERG_INV_A);
        } else {
            eq(
                staking.balanceOf(address(this)), 
                staking.lockedBalanceOf(address(this)),
                EMERG_INV_A
            );
        }
    }
}