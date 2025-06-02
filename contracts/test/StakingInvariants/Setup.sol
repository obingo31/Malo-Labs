pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-2.0

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

// Helpers
import {Utils} from "@recon/Utils.sol";

// Your deps
import "../../src/Staking.sol";
import {StakingTokenMock} from "./mocks/StakingTokenMock.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    Staking public staking;
    StakingTokenMock public stakingToken;
    MockERC20 public maloToken;
    uint256 public constant REWARD_PERIOD = 1 weeks;

    // Track all test actors
    address[] internal allActors;

    /// === Recon-Chimera Hybrid Setup === ///
    function setup() internal virtual override {
        // 1. Deploy protocol tokens using AssetManager
        stakingToken = StakingTokenMock(payable(_newAsset(18)));
        maloToken = MockERC20(payable(_newAsset(18)));

        // Additional test assets
        _newAsset(18);
        _newAsset(8);
        _newAsset(6);

        // 2. Initialize actors (admin + 2 test actors)
        address[3] memory initialActors = [address(this), address(0x411c3), address(0xb0b)];

        for (uint256 i = 0; i < initialActors.length; i++) {
            _addActor(initialActors[i]);
        }
        allActors = _getActors();

        // 3. Deploy staking contract
        staking = new Staking(
            address(stakingToken),
            address(maloToken),
            address(this), // owner
            REWARD_PERIOD,
            address(this) // feeRecipient
        );

        // 4. Configure tokens and approvals
        _configureTokensAndApprovals();

        // 5. Setup roles
        _setupRoles();
    }

    /// === Token Configuration === ///
    function _configureTokensAndApprovals() internal {
        uint256 maxAmount = type(uint88).max;

        // Configure all actors
        for (uint256 i = 0; i < allActors.length; i++) {
            address actor = allActors[i];

            // Mint tokens (from contract as minter)
            vm.prank(address(this));
            stakingToken.mint(actor, maxAmount);

            vm.prank(address(this));
            maloToken.mint(actor, maxAmount);

            // Set approvals (as actor)
            vm.prank(actor);
            stakingToken.approve(address(staking), type(uint256).max);

            vm.prank(actor);
            maloToken.approve(address(staking), type(uint256).max);
        }

        // Fund staking contract with rewards
        vm.prank(address(this));
        maloToken.mint(address(staking), maxAmount);
    }

    /// === Role Management === ///
    function _setupRoles() internal {
        // Admin roles
        vm.prank(address(this));
        staking.grantRole(keccak256("LOCK_MANAGER_ROLE"), address(this));

        vm.prank(address(this));
        staking.grantRole(keccak256("PAUSER_ROLE"), address(this));
    }

    /// === Modifiers === ///
    modifier asAdmin() {
        vm.prank(address(this));
        _;
    }

    modifier asActor() {
        vm.prank(_getActor());
        _;
    }
}
