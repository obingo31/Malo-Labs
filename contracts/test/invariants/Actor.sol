// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Actor {
    address[] public approvedContracts;
    address[] public tokens;

    constructor(address[] memory _tokens, address stakingContract) {
        tokens = _tokens;
        approvedContracts.push(stakingContract);

        // Approve staking contract for all tokens
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(stakingContract, type(uint256).max);
        }
    }

    function proxy(address target, bytes calldata data) external returns (bool, bytes memory) {
        require(_isApproved(target), "Unauthorized target");
        return target.call(data);
    }

    function _isApproved(address target) private view returns (bool) {
        for (uint256 i = 0; i < approvedContracts.length; i++) {
            if (approvedContracts[i] == target) return true;
        }
        return false;
    }

    receive() external payable {}
}
