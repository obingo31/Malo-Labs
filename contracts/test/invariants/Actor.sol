// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract Actor {
    event ProxyCall(address indexed target, bool success, bytes returnData);

    address public lastTarget;
    mapping(address => mapping(address => uint256)) public allowances;
    address[] internal approvedTokens;
    address[] internal approvedContracts;

    constructor(address[] memory _tokens, address[] memory _contracts) payable {
        approvedTokens = _tokens;
        approvedContracts = _contracts;

        // Batch approvals using multicall pattern
        for (uint256 i = 0; i < _tokens.length; i++) {
            _batchApprove(_tokens[i], _contracts);
        }
    }

    function proxy(address _target, bytes memory _calldata) public returns (bool success, bytes memory returnData) {
        (success, returnData) = _target.call(_calldata);
        _handleCallResult(_target, success, returnData);
    }

    function proxy(address _target, bytes memory _calldata, uint256 value)
        public
        returns (bool success, bytes memory returnData)
    {
        (success, returnData) = _target.call{value: value}(_calldata);
        _handleCallResult(_target, success, returnData);
    }

    function _handleCallResult(address target, bool success, bytes memory returnData) internal {
        lastTarget = target;
        emit ProxyCall(target, success, returnData);

        if (!success) {
            // Enhanced error handling
            if (returnData.length >= 4) {
                bytes4 errorSelector;
                assembly {
                    errorSelector := mload(add(returnData, 0x20))
                }

                // Handle common error types
                if (errorSelector == 0x4e487b71) {
                    // Panic error
                    uint256 code = abi.decode(returnData, (uint256));
                    require(false, string(abi.encodePacked("Panic: ", code)));
                } else if (errorSelector == 0x08c379a0) {
                    // Error(string)
                    string memory message = abi.decode(returnData, (string));
                    require(false, message);
                }
            }
            revert("Unknown error");
        }
    }

    function _batchApprove(address token, address[] memory _contracts) internal {
        IERC20 t = IERC20(token);
        for (uint256 j = 0; j < _contracts.length; j++) {
            if (allowances[token][_contracts[j]] == 0) {
                t.approve(_contracts[j], type(uint256).max);
                allowances[token][_contracts[j]] = type(uint256).max;
            }
        }
    }

    // Additional management functions
    function revokeApproval(address token, address spender) external {
        IERC20(token).approve(spender, 0);
        allowances[token][spender] = 0;
    }

    function getApprovedTokens() external view returns (address[] memory) {
        return approvedTokens;
    }

    function getApprovedContracts() external view returns (address[] memory) {
        return approvedContracts;
    }

    receive() external payable {}
}
