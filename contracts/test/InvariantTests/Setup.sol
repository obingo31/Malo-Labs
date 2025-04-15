// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";
import {Utils} from "@recon/Utils.sol";
import {MALGovernanceStaking} from "src/MALGovernanceStaking.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockVotesToken} from "./MockVotesToken.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    MALGovernanceStaking public malGovernanceStaking;
    address public daoMultisig;

    MockVotesToken token = new MockVotesToken("GovToken", "GOV");
    IERC20 public governanceToken;
    IERC20 public utilityToken;

    function setup() internal virtual override {
        // Initialize actors
        _addActor(address(0x411c3));
        _addActor(address(0xb0b));
        _addActor(address(0xA11CE));
        daoMultisig = _getActors()[0];

        // Deploy and cast tokens
        governanceToken = token;
        utilityToken = IERC20(_newAsset(18));

        // Deploy governance staking contract with address casting
        malGovernanceStaking = new MALGovernanceStaking(address(governanceToken), address(utilityToken), daoMultisig);

        // Configure approvals
        address[] memory actors = _getActors();
        address[] memory contractsToApprove = new address[](1);
        contractsToApprove[0] = address(malGovernanceStaking);

        _finalizeAssetDeployment(actors, contractsToApprove, type(uint88).max);
    }

    function _currentActor() internal view returns (address) {
        return _getActor();
    }

    function _getAssetAddress(uint256 index) internal view returns (address) {
        address[] memory assets = _getAssets();
        require(index < assets.length, "Index out of bounds");
        return assets[index];
    }

    modifier asAdmin() {
        vm.prank(daoMultisig);
        _;
    }

    modifier asActor() {
        vm.prank(_currentActor());
        _;
    }
}
