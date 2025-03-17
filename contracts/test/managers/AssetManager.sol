// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {console} from "forge-std/console.sol";

abstract contract AssetManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Custom errors
    error NotSetup();
    error Exists();
    error NotAdded();
    error InvalidAddress();
    error NoDifferentAsset();

    // The current active asset
    address private __asset;

    // Set of all managed assets
    EnumerableSet.AddressSet private _assets;

    // Constructor initializes the contract itself as the default asset
    constructor() {
        _assets.add(address(this));
        __asset = address(this);
    }

    // Get the current active asset
    function _getAsset() internal view returns (address) {
        if (__asset == address(0)) {
            revert NotSetup();
        }
        return __asset;
    }

    // Get an asset different from the currently active one
    function _getDifferentAsset() internal view returns (address) {
        address[] memory assets_ = _getAssets();
        for (uint256 i = 0; i < assets_.length; i++) {
            if (assets_[i] != __asset) {
                return assets_[i];
            }
        }
        revert NoDifferentAsset();
    }

    // Get all assets in the set
    function _getAssets() internal view returns (address[] memory) {
        return _assets.values();
    }

    // Create a new mock ERC20 asset and add it to the set
    function _newAsset() internal returns (address) {
        address asset_ = address(new ERC20Mock("Test Token", "TST"));
        _addAsset(asset_);
        _enableAsset(asset_);
        return asset_;
    }

    // Enable a specific asset as the active one
    function _enableAsset(address target) internal {
        if (!_assets.contains(target)) {
            revert NotAdded();
        }
        __asset = target;
    }

    // Disable the current asset and reset to the default (contract itself)
    function _disableAsset() internal {
        __asset = address(this);
    }

    // Add a new asset to the set
    function _addAsset(address target) internal {
        if (target == address(0)) revert InvalidAddress();
        if (_assets.contains(target)) revert Exists();
        _assets.add(target);
    }

    // Remove an asset from the set
    function _removeAsset(address target) internal {
        if (!_assets.contains(target)) revert NotAdded();
        if (target == __asset) _disableAsset();
        _assets.remove(target);
    }

    // Switch to a random asset from the set
    function _switchAsset(uint256 entropy) internal {
        _disableAsset();
        _enableAsset(_assets.at(entropy % _assets.length()));
    }

    // Mint initial balances and approve allowances for the active asset
    function _finalizeAssetDeployment(address[] memory actorsArray, address[] memory approvalArray, uint256 amount)
        internal
    {
        _mintAssetToAllActors(actorsArray, amount);
        for (uint256 i = 0; i < approvalArray.length; i++) {
            _approveAssetToAddressForAllActors(actorsArray, approvalArray[i]);
        }
    }

    // Mint the active asset to all actors
    function _mintAssetToAllActors(address[] memory actorsArray, uint256 amount) internal {
        address asset = _getAsset();
        for (uint256 i = 0; i < actorsArray.length; i++) {
            vm.prank(actorsArray[i]);
            ERC20Mock(asset).mint(actorsArray[i], amount);
        }
    }

    // Approve the active asset to a specific address for all actors
    function _approveAssetToAddressForAllActors(address[] memory actorsArray, address addressToApprove) internal {
        address asset = _getAsset();
        for (uint256 i = 0; i < actorsArray.length; i++) {
            vm.prank(actorsArray[i]);
            ERC20Mock(asset).approve(addressToApprove, type(uint256).max);
        }
    }
}
