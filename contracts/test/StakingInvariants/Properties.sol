// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {
    // ███████╗████████╗ █████╗ ██╗  ██╗██╗███╗   ██╗ ██████╗
    // ██╔════╝╚══██╔══╝██╔══██╗██║ ██╔╝██║████╗  ██║██╔════╝
    // ███████╗   ██║   ███████║█████╔╝ ██║██╔██╗ ██║██║  ███╗
    // ╚════██║   ██║   ██╔══██║██╔═██╗ ██║██║╚██╗██║██║   ██║
    // ███████║   ██║   ██║  ██║██║  ██╗██║██║ ╚████║╚██████╔╝
    // ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝

    function invariant_CORE_INV_A() public {
        uint256 totalBal;
        address[] memory actors = _getActors();
        for (uint256 i; i < actors.length; ++i) {
            totalBal += staking.balanceOf(actors[i]);
        }
        eq(totalBal, staking.totalStaked(), CORE_GPOST_A);
    }

    function invariant_CORE_INV_B() public {
        address actor = _getActor();
        uint256 totalBalance = staking.lockedBalanceOf(actor) + staking.unlockedBalanceOf(actor);
        eq(totalBalance, staking.balanceOf(actor), CORE_GPOST_B);
    }

    function invariant_CORE_INV_C() public {
        lte(staking.protocolFee(), staking.MAX_FEE(), CORE_GPOST_C);
    }

    function invariant_CORE_INV_D() public {
        t(staking.feeRecipient() != address(0), CORE_GPOST_D);
    }

    // ██████╗ ███████╗██╗    ██╗ █████╗ ██████╗ ██████╗
    // ██╔══██╗██╔════╝██║    ██║██╔══██╗██╔══██╗██╔══██╗
    // ██████╔╝█████╗  ██║ █╗ ██║███████║██████╔╝██║  ██║
    // ██╔══██╗██╔══╝  ██║███╗██║██╔══██║██╔══██╗██║  ██║
    // ██║  ██║███████╗╚███╔███╔╝██║  ██║██║  ██║██████╔╝
    // ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝

    function invariant_REWARD_INV_A() public {
        uint256 rewards = staking.totalRewardsDistributed();
        uint256 balance = staking.maloToken().balanceOf(address(staking));
        lte(rewards, balance, REWARD_GPOST_A);
    }

    // ██╗      ██████╗  ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗
    // ██║     ██╔═══██╗██╔════╝██║ ██╔╝██║████╗  ██║██╔════╝
    // ██║     ██║   ██║██║     █████╔╝ ██║██╔██╗ ██║██║  ███╗
    // ██║     ██║   ██║██║     ██╔═██╗ ██║██║╚██╗██║██║   ██║
    // ███████╗╚██████╔╝╚██████╗██║  ██╗██║██║ ╚████║╚██████╔╝
    // ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝

    function invariant_LOCK_INV_A() public {
        address[] memory actors = _getActors();
        uint256 totalLocked;
        for (uint256 i; i < actors.length; ++i) {
            totalLocked += staking.lockedBalanceOf(actors[i]);
        }
        lte(totalLocked, staking.totalStaked(), LOCK_GPOST_A);
    }

    function invariant_LOCK_INV_B() public {
        address[] memory actors = _getActors();
        for (uint256 i; i < actors.length; ++i) {
            for (uint256 j; j < actors.length; ++j) {
                (uint256 locked, uint256 allowance) = staking.getLock(actors[i], actors[j]);
                if (allowance > 0) {
                    lte(locked, allowance, LOCK_HSPOST_E);
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

    function invariant_TOKEN_INV_A() public {
        uint256 onChain = staking.stakingToken().balanceOf(address(staking));
        eq(onChain, staking.totalStaked(), TOKEN_GPOST_A);
    }

    function invariant_TOKEN_INV_B() public {
        uint256 rewards = staking.totalRewardsDistributed();
        uint256 balance = staking.maloToken().balanceOf(address(staking));
        lte(rewards, balance, TOKEN_GPOST_B);
    }

    // ███████╗███╗   ███╗███████╗███████╗██████╗ ██████╗ ██╗   ██╗
    // ██╔════╝████╗ ████║██╔════╝██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
    // █████╗  ██╔████╔██║█████╗  █████╗  ██████╔╝██████╔╝ ╚████╔╝
    // ██╔══╝  ██║╚██╔╝██║██╔══╝  ██╔══╝  ██╔══██╗██╔══██╗  ╚██╔╝
    // ███████╗██║ ╚═╝ ██║███████╗███████╗██║  ██║██║  ██║   ██║
    // ╚══════╝╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝

    function invariant_EMERG_INV_A() public {
        address actor = _getActor();
        if (staking.paused()) {
            eq(staking.balanceOf(actor), 0, EMERG_GPOST_A);
        } else {
            eq(
                staking.balanceOf(actor),
                staking.lockedBalanceOf(actor) + staking.unlockedBalanceOf(actor),
                EMERG_GPOST_A
            );
        }
    }

    // ███████╗███████╗███████╗
    // ██╔════╝██╔════╝██╔════╝
    // █████╗  █████╗  █████╗
    // ██╔══╝  ██╔══╝  ██╔══╝
    // ██║     ███████╗██║
    // ╚═╝     ╚══════╝╚═╝

    function invariant_FEE_INV_A() public {
        uint256 feeBalance = staking.maloToken().balanceOf(staking.feeRecipient());
        uint256 expectedFees = staking.totalRewardsDistributed() * staking.protocolFee() / 1000;
        gte(feeBalance, expectedFees, FEE_HSPOST_B);
    }

    //  █████╗  ██████╗ ██████╗███████╗███████╗███████╗
    // ██╔══██╗██╔════╝ ██╔══██╗██╔════╝██╔════╝██╔════╝
    // ███████║██║  ███╗██████╔╝█████╗  █████╗  █████╗
    // ██╔══██║██║   ██║██╔═══╝ ██╔══╝  ██╔══╝  ██╔══╝
    // ██║  ██║╚██████╔╝██║     ███████╗███████╗███████╗
    // ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝╚══════╝╚══════╝

    function invariant_ACCESS_INV_A() public {
        // Note: Exact role-based access control check depends on staking contract's implementation.
        // Here, we assume setProtocolFee is restricted to authorized roles.
        t(staking.protocolFee() <= staking.MAX_FEE(), ACCESS_GPOST_A);
    }
}
