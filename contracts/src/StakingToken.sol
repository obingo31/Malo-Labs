// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, address initialOwner)
        ERC20(name, symbol)
        Ownable(initialOwner) // Pass the owner directly here
    {}

    // Mint function, restricted to the owner (test contract or deployer)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
