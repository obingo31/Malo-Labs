// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "src/Staking.sol";
import {Errors} from "src/libraries/Errors.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

contract StakingTest is Test {
    Staking public staking;
    MockERC20 public stakingToken;
    MockERC20 public maloToken;
    address public constant feeRecipient = address(0xFee);
    address public user1 = address(0x1);
    uint256 public constant REWARD_PERIOD = 7 days;

    function setUp() public {
        stakingToken = new MockERC20("Staking Token", "STK");
        maloToken = new MockERC20("Reward Token", "MALO");

        staking = new Staking(address(stakingToken), address(maloToken), address(this), REWARD_PERIOD, feeRecipient);
    }

    // When staking tokens, it should update the user's balance
    function test_WhenStakingTokens() public {
        uint256 stakeAmount = 100e18;

        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staking), stakeAmount);

        staking.stake(stakeAmount);

        assertEq(staking.balanceOf(address(this)), stakeAmount, "Balance should update");
        assertEq(stakingToken.balanceOf(address(staking)), stakeAmount, "Tokens should be in contract");
    }

    // When staking zero tokens, it should revert
    function test_RevertWhen_StakingZeroTokens() public {
        // Setup
        vm.expectRevert(Errors.ZeroAmount.selector);

        staking.stake(0);
    }

    //When staking on behalf of another user
    function test_WhenStakingOnBehalfOfAnotherUser() public {
        uint256 stakeAmount = 100e18;

        stakingToken.mint(address(this), stakeAmount);
        stakingToken.approve(address(staking), stakeAmount);

        staking.stakeFor(user1, stakeAmount);

        assertEq(staking.balanceOf(user1), stakeAmount, "Target balance should update");
        assertEq(staking.balanceOf(address(this)), 0, "Caller balance should not change");
        assertEq(stakingToken.balanceOf(address(staking)), stakeAmount, "Tokens should be in contract");
    }
}
