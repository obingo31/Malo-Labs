// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Aborter
 * @dev Configurable contract that reverts on calls, useful for testing failure cases.
 */
contract Aborter {
    string public abortMessage;
    bool public shouldAbort;
    bytes4 public allowedSelector;

    /**
     * @dev Initialize with custom abort message and initial state
     */
    constructor(string memory _abortMessage, bool _initialAbortState) {
        abortMessage = _abortMessage;
        shouldAbort = _initialAbortState;
    }

    /**
     * @dev Configure abort behavior
     * @param _message Custom abort message
     * @param _shouldAbort Whether calls should revert
     * @param _allowedSelector Function selector that bypasses abort
     */
    function configureAbort(string memory _message, bool _shouldAbort, bytes4 _allowedSelector) external {
        abortMessage = _message;
        shouldAbort = _shouldAbort;
        allowedSelector = _allowedSelector;
    }

    /**
     * @dev Fallback function that reverts when shouldAbort is true
     */
    fallback() external payable virtual {
        if (shouldAbort && msg.sig != allowedSelector) {
            revert(abortMessage);
        }
    }

    /**
     * @dev Receive function that reverts when shouldAbort is true
     */
    receive() external payable virtual {
        if (shouldAbort) {
            revert(abortMessage);
        }
    }
}

/**
 * @title AborterWithPrecision
 * @dev Extends Aborter with precision functions for token testing
 */
contract AborterWithPrecision is Aborter {
    uint8 public constant decimals = 18;
    string public constant symbol = "ABT";
    string public constant name = "Aborter Token";

    constructor() Aborter("AborterWithPrecision: call aborted", true) {}

    /**
     * @notice Returns the token precision
     * @return The fixed precision (18)
     */
    function queryPrecision() external pure returns (uint8) {
        return decimals;
    }

    /**
     * @dev Mock ERC20 transfer that aborts based on configuration
     */
    function transfer(address, uint256) external view returns (bool) {
        if (shouldAbort) {
            revert(abortMessage);
        }
        return true;
    }
}

/**
 * @title AborterWithSelectiveFunctions
 * @dev Advanced aborter with function-specific abort control
 */
contract AborterWithSelectiveFunctions is Aborter {
    struct FunctionConfig {
        bool shouldAbort;
        string abortMessage;
    }

    mapping(bytes4 => FunctionConfig) public functionConfigs;

    /**
     * @dev Constructor passes the required arguments to the base Aborter contract.
     */
    constructor() Aborter("AborterWithSelectiveFunctions: call aborted", true) {}

    /**
     * @dev Configure abort for specific function selector
     */
    function configureFunctionAbort(bytes4 selector, bool _shouldAbort, string memory _abortMessage) external {
        functionConfigs[selector] = FunctionConfig(_shouldAbort, _abortMessage);
    }

    /**
     * @dev Fallback with function-specific abort control
     */
    fallback() external payable override {
        bytes4 selector = msg.sig;
        FunctionConfig memory config = functionConfigs[selector];

        if (config.shouldAbort) {
            revert(config.abortMessage);
        }

        // Handle known functions
        if (selector == this.getVersion.selector) {
            assembly {
                mstore(0, 1)
                return(0, 32)
            }
        }
    }

    /**
     * @dev Example function that can be called when not aborted
     */
    function getVersion() external pure returns (uint256) {
        return 1;
    }
}
