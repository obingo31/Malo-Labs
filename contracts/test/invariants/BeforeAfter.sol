// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

import "./Setup.sol";
import {IHevm} from "@chimera/Hevm.sol";
import {ExpectedErrors} from "./ExpectedErrors.sol";

abstract contract BeforeAfter is Setup {
    IHevm internal immutable hevm = IHevm(HEVM_ADDRESS);

    uint256 internal baseSnapshotId;
    uint256 public snapshotRegenerationCount;
    uint256 public maxSnapshotRegenerations = 5;
    bool internal useSnapshots;
    uint256 public unexpectedErrorCount;
    uint256 public maxUnexpectedErrors = 3;
    
    mapping(bytes4 => bool) internal validSnapshotErrors;
    mapping(bytes4 => string) internal errorMessages;

    event BaseSnapshotCreated(uint256 snapshotId);
    event SnapshotReverted(uint256 snapshotId, bool success, bytes4 errorSelector, bytes errorData);
    event SnapshotRegenerated(uint256 newSnapshotId);

    error ExcessiveErrors();
    error SnapshotProtectionDisabled();
    error InvalidSnapshotIdentifier(uint256 snapshotId);
    error MaxRegenerationsReached();
    error SnapshotSystemFailure(string message);

    function setUp() public virtual override {
        super.setUp();
        _initializeErrorRegistry();
        _resetSnapshotState();
        _createBaseSnapshot();
    }

    function _initializeErrorRegistry() internal {
        validSnapshotErrors[ExpectedErrors.InvalidSnapshotId.selector] = true;
        validSnapshotErrors[ExpectedErrors.SnapshotFailed.selector] = true;
        
        errorMessages[ExpectedErrors.InvalidSnapshotId.selector] = "Invalid snapshot ID";
        errorMessages[ExpectedErrors.SnapshotFailed.selector] = "Snapshot operation failed";
    }

    function beforeEach() public virtual {
        if (useSnapshots) {
            _revertToSnapshotWithValidation();
        }
        _resetSnapshotState();
    }

    modifier validateState() {
        if (!useSnapshots) revert SnapshotProtectionDisabled();
        _;
    }

    function _resetSnapshotState() internal {
        useSnapshots = true;
        unexpectedErrorCount = 0;
    }

    function _createBaseSnapshot() internal {
        (bool success, bytes memory data) = address(hevm).call(abi.encodeWithSignature("snapshot()"));
        if (!success) _handleSnapshotError(data);

        uint256 newSnapshotId = abi.decode(data, (uint256));
        if (newSnapshotId <= baseSnapshotId) {
            revert SnapshotSystemFailure("Snapshot ID regression detected");
        }
        
        baseSnapshotId = newSnapshotId;
        emit BaseSnapshotCreated(baseSnapshotId);
    }

    function _revertToSnapshotWithValidation() internal validateState {
        if (unexpectedErrorCount >= maxUnexpectedErrors) revert ExcessiveErrors();

        (bool success, bytes memory data) = 
            address(hevm).call(abi.encodeWithSignature("revertTo(uint256)", baseSnapshotId));

        if (!success) {
            bytes4 errorSelector = bytes4(data);
            string memory errorMsg = errorMessages[errorSelector];

            if (errorSelector == ExpectedErrors.InvalidSnapshotId.selector) {
                _regenerateSnapshot();
                return;
            }

            if (validSnapshotErrors[errorSelector]) {
                emit SnapshotReverted(baseSnapshotId, false, errorSelector, data);
                return;
            }

            unexpectedErrorCount++;
            emit SnapshotReverted(baseSnapshotId, false, errorSelector, data);
            revert SnapshotSystemFailure(errorMsg);
        }

        emit SnapshotReverted(baseSnapshotId, true, bytes4(0), "");
    }

    function _regenerateSnapshot() internal {
        if (++snapshotRegenerationCount > maxSnapshotRegenerations) {
            useSnapshots = false;
            revert MaxRegenerationsReached();
        }

        try this._createBaseSnapshot() {
            emit SnapshotRegenerated(baseSnapshotId);
        } catch (bytes memory reason) {
            useSnapshots = false;
            revert SnapshotSystemFailure(_decodeError(reason));
        }
    }

    function _handleSnapshotError(bytes memory data) internal view {
        bytes4 selector = bytes4(data);
        string memory message = errorMessages[selector];
        if (bytes(message).length == 0) message = "Unknown snapshot error";
        revert SnapshotSystemFailure(message);
    }

    function _decodeError(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "Empty error data";
        if (data.length < 4) return "Malformed error data";
        
        bytes4 selector = bytes4(data);
        if (selector == ExpectedErrors.InvalidSnapshotId.selector) return "Invalid snapshot ID";
        if (selector == ExpectedErrors.SnapshotFailed.selector) return "Snapshot failed";
        
        return string(abi.encodePacked("Unknown error (0x", _toHex(data), ")"));
    }

    function _toHex(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint8(data[i] >> 4)];
            str[3+i*2] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }

    function getSnapshotStatus()
        public
        view
        returns (
            uint256 baseId,
            bool snapshotsActive,
            uint256 errorCount,
            uint256 regenerations
        )
    {
        return (baseSnapshotId, useSnapshots, unexpectedErrorCount, snapshotRegenerationCount);
    }
}