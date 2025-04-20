// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

// Helpers
import {Utils} from "@recon/Utils.sol";

// Your deps
import "../../src/Gov.sol";
import "../../src/GovToken.sol";
import "../InvariantTests/MockVotesToken.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    Gov gov;
    GovToken govToken;
    MockVotesToken mockVotesToken;
    TimelockController public timelock; // 🚨 Add this line

    /// === Setup === ///
    function setup() internal virtual override {
        govToken = new GovToken("GovToken", "GTK");
        // Deploy timelock with Gov as the only proposer
        address[] memory proposers = new address[](1);
        proposers[0] = address(gov); // Gov is proposer
        address[] memory executors = new address[](1);
        executors[0] = address(0); // Public execution
        timelock = new TimelockController( // ✅ Now stored as state var
        1 days, proposers, executors, address(this));
        //  TimelockController timelock = new TimelockController(1 days, proposers, executors, address(this));
        // Deploy Gov with secure parameters
        gov = new Gov(IVotes(address(govToken)), timelock);
        // Revoke test contract's admin role
        timelock.grantRole(timelock.DEFAULT_ADMIN_ROLE(), address(0));
    }

    /// === MODIFIERS === ///
    /// Prank admin and actor

    modifier asAdmin() {
        vm.prank(address(this));
        _;
    }

    modifier asActor() {
        vm.prank(address(_getActor()));
        _;
    }
}
