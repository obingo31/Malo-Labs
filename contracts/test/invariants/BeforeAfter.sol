// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Staking} from "src/Staking.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {Constants} from "./Constants.sol";

contract BeforeAfter is Test, Constants {
    Staking public staking;
    ERC20Mock public stakingToken;
    ERC20Mock public maloToken;
    address public owner;
    address public feeRecipient;

    function setUp() public virtual {
        owner = address(this);
        feeRecipient = address(0x123);

        // Initialize mock tokens
        stakingToken = new ERC20Mock("Staking Token", "STK");
        maloToken = new ERC20Mock("Malo Token", "MALO");

        // Mint tokens
        stakingToken.mint(address(this), INITIAL_BALANCE);
        maloToken.mint(address(this), INITIAL_BALANCE);

        // Deploy staking contract
        staking = new Staking(address(stakingToken), address(maloToken), owner, REWARD_EPOCH, feeRecipient);

        // Approve staking contract to spend tokens
        stakingToken.approve(address(staking), type(uint256).max);
        maloToken.approve(address(staking), type(uint256).max);
    }

    function _beforeEach() internal virtual {}
    function _afterEach() internal virtual {}
}
