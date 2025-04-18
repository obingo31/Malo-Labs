// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RewardToken
 * @notice A minimal ERC20 reward token with mint and burn functionality.
 */
abstract contract rewardToken is ERC20, Ownable {
    /**
     * @notice Constructor that initializes the reward token with its name and symbol.
     */
    constructor() ERC20("Reward Token", "RWD") {}

    /**
     * @notice Mints new tokens to a specified address.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from the caller's account.
     * @param amount The amount of tokens to burn.
     */
    function burn(
        uint256 amount
    ) external {
        _burn(msg.sender, amount);
    }
}
