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
import "../../src/Staking.sol";

import {IStaking} from "../../src/interfaces/IStaking.sol";
import {StakingTokenMock} from "./mocks/StakingTokenMock.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    Staking public staking;
    StakingTokenMock public stakingToken;
    MockERC20 public maloToken;
    uint256 public constant REWARD_PERIOD = 1 weeks;
    address public feeRecipient;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        // Deploy mock tokens via AssetManager

        stakingToken = StakingTokenMock(payable(_newAsset(18)));
        maloToken = MockERC20(payable(_newAsset(18)));
        _newAsset(18);
        _newAsset(8);
        _newAsset(6);

        _addActor(address(0x411c3));
        _addActor(address(0xb0b));
        _addActor(address(0xA11CE));

        // Assign fee recipient and initial owner to this contract
        feeRecipient = address(this);

        // Deploy the staking contract
        staking = new Staking(address(stakingToken), address(maloToken), address(this), REWARD_PERIOD, feeRecipient);

        // Mint initial balances for actors
        address[] memory approvalArray = new address[](3);
        approvalArray[0] = address(this);
        approvalArray[1] = address(0x411c3);
        approvalArray[2] = address(0xb0b);

        _finalizeAssetDeployment(_getActors(), approvalArray, type(uint88).max);
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
