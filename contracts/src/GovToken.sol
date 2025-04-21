// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract GovToken is ERC20, ERC20Permit, ERC20Votes {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    ///@dev update function is used to update the votes of a given address
    ///@param from The address of the sender
    ///@param to The address of the receiver
    ///@param value The amount of tokens to be transferred
    /// Combined override for ERC20Votes and ERC20
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /// Combined override for ERC20
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        return super.approve(spender, value);
    }

    ///@dev nonces function is used to get the nonce of a given address
    ///@param owner The address of the owner
    // Explicit override for Nonces conflict resolution
    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
