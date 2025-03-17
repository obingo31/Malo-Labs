// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "src/libraries/Errors.sol";

/**
 * @title ActorManager
 * @dev Manages multiple actors for testing purposes with enhanced safety checks
 */
abstract contract ActorManager is BaseSetup {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Custom errors that are not in the Errors library
    error ActorNotAdded();
    error DefaultActor();
    error NoDifferentActor();

    address private _actor;
    EnumerableSet.AddressSet private _actors;

    constructor() {
        _actors.add(address(this));
        _actor = address(this);
    }

    modifier useActor() {
        vm.prank(_getActor());
        _;
    }

    function _getActor() internal view returns (address) {
        return _actor;
    }

    function _getDifferentActor() internal view returns (address) {
        address[] memory actors = _getActors();

        for (uint256 i = 0; i < actors.length; i++) {
            if (actors[i] != _actor) {
                return actors[i];
            }
        }
        revert NoDifferentActor();
    }

    function _getRandomActor(uint256 entropy) internal view returns (address) {
        address[] memory actors = _getActors();
        return actors[entropy % actors.length];
    }

    function _getActors() internal view returns (address[] memory) {
        return _actors.values();
    }

    function _enableActor(address target) internal {
        require(_actors.contains(target), "Actor not registered");
        _actor = target;
    }

    function _disableActor() internal {
        _actor = address(this);
    }

    function _addActor(address target) internal {
        if (target == address(0)) revert Errors.InvalidAddress();
        if (target == address(this)) revert DefaultActor();
        if (!_actors.add(target)) revert Errors.ActorExists();
    }

    function _removeActor(address target) internal {
        if (target == address(this)) revert DefaultActor();
        if (!_actors.contains(target)) revert ActorNotAdded();

        if (target == _actor) {
            _disableActor();
        }
        _actors.remove(target);
    }

    function _switchActor(uint256 entropy) internal {
        _disableActor();
        _enableActor(_actors.at(entropy % _actors.length()));
    }
}
