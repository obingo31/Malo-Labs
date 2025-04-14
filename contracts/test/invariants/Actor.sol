// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract Actor {
    address public lastTarget;
    address[] internal tokens;
    address[] internal contracts;

    constructor(address[] memory _tokens, address[] memory _contracts) payable {
        tokens = _tokens;
        contracts = _contracts;
    }

    function approveToken(address token, address spender, uint256 amount) external {
        IERC20(token).approve(spender, amount);
    }

    function batchApprove(
        address[] memory _tokens, 
        address[] memory _spenders, 
        uint256[] memory _amounts
    ) external {
        require(
            _tokens.length == _spenders.length && 
            _spenders.length == _amounts.length,
            "Array length mismatch"
        );
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).approve(_spenders[i], _amounts[i]);
        }
    }

    function proxy(address _target, bytes memory _calldata) public returns (bool success, bytes memory returnData) {
        require(_target != address(0), "Invalid target");
        (success, returnData) = _target.call(_calldata);
        lastTarget = _target;
        handleAssertionError(success, returnData);
    }

    function proxy(address _target, bytes memory _calldata, uint256 value)
        public
        returns (bool success, bytes memory returnData)
    {
        require(_target != address(0), "Invalid target");
        require(address(this).balance >= value, "Insufficient ETH balance");
        (success, returnData) = _target.call{value: value}(_calldata);
        lastTarget = _target;
        handleAssertionError(success, returnData);
    }

    function handleAssertionError(bool success, bytes memory returnData) internal pure {
        if (!success) {
            if (returnData.length == 36) {
                bytes4 selector;
                uint256 code;
                assembly {
                    selector := mload(add(returnData, 0x20))
                    code := mload(add(returnData, 0x24))
                }
                if (selector == bytes4(0x4e487b71) && code == 1) assert(false);
            }
            revert("Actor call failed");
        }
    }

    receive() external payable {}
}