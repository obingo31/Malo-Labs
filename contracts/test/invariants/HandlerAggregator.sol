// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ExpectedErrors} from "./ExpectedErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Properties} from "./Properties.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Staking} from "src/Staking.sol";

/// @title HandlerAggregator
/// @notice Aggregates staking handlers for testing and invariant validation
/// @dev Extends `Properties` to ensure proper state testing
abstract contract HandlerAggregator is Properties, ExpectedErrors {
    using SafeERC20 for IERC20;

    MaloStaking private immutable staking;
    IERC20 private immutable stakingToken;
    IERC20 private immutable rewardToken;

    constructor(MaloStaking _staking) Properties(_staking) {
        staking = _staking;
        stakingToken = IERC20(_staking.stakingToken());
        rewardToken = IERC20(_staking.rewardToken());
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                Staking Handler Functions                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function handler_stake(uint256 amount, address user) external checkExpectedErrors("Stake") {
        require(amount > 0, "Amount must be positive");
        require(stakingToken.balanceOf(user) >= amount, "Insufficient user balance");
        require(stakingToken.allowance(user, address(staking)) >= amount, "Insufficient allowance");

        uint256 preTotalStaked = staking.totalStaked();
        uint256 preContractBalance = stakingToken.balanceOf(address(staking));

        vm.prank(user);
        staking.stake(amount);

        // Postcondition: Ensure state is correctly updated
        assertEq(staking.stakedBalanceOf(user), preContractBalance + amount, "Stake: User balance mismatch");
        assertEq(staking.totalStaked(), preTotalStaked + amount, "Stake: Total staked mismatch");
        assertEq(stakingToken.balanceOf(address(staking)), preContractBalance + amount, "Stake: Contract balance mismatch");
    }

    function handler_withdraw(uint256 amount, address user) external checkExpectedErrors("Withdraw") {
        require(amount > 0, "Amount must be positive");
        require(staking.stakedBalanceOf(user) >= amount, "Insufficient staked balance");
        require(stakingToken.balanceOf(address(staking)) >= amount, "Insufficient contract liquidity");

        uint256 preTotalStaked = staking.totalStaked();
        uint256 preContractBalance = stakingToken.balanceOf(address(staking));

        vm.prank(user);
        staking.withdraw(amount);

        // Postcondition: Ensure state is correctly updated
        assertEq(staking.stakedBalanceOf(user), preContractBalance - amount, "Withdraw: User balance mismatch");
        assertEq(staking.totalStaked(), preTotalStaked - amount, "Withdraw: Total staked mismatch");
        assertEq(stakingToken.balanceOf(address(staking)), preContractBalance - amount, "Withdraw: Contract balance mismatch");
    }

    function handler_claimRewards(address user, address rewardTokenAddress) external checkExpectedErrors("ClaimRewards") {
        uint256 rewardsBefore = rewardToken.balanceOf(user);
        uint256 claimable = staking.earned(user);

        require(claimable > 0, "No rewards to claim");

        vm.prank(user);
        staking.claimRewards(rewardTokenAddress);

        uint256 rewardsAfter = rewardToken.balanceOf(user);
        assertEq(rewardsAfter, rewardsBefore + claimable, "ClaimRewards: Incorrect reward amount transferred");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               Global Postconditions (GPOST)                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function checkGlobalPostconditions() external view {
        uint256 totalStaked = staking.totalStaked();
        uint256 contractBalance = stakingToken.balanceOf(address(staking));

        // GPOST 1: Sum of balances matches total supply
        uint256 sumBalances;
        address[] memory users = getActiveUsers();
        for (uint256 i = 0; i < users.length; i++) {
            sumBalances += staking.stakedBalanceOf(users[i]);
        }
        assertEq(sumBalances, totalStaked, "GPOST: Balance sum mismatch");

        // GPOST 2: Contract token balance matches total supply
        assertEq(contractBalance, totalStaked, "GPOST: Contract balance mismatch");

        // GPOST 3: Reward safety checks
        assertLe(staking.totalRewards(), rewardToken.balanceOf(address(staking)), "GPOST: Insufficient reward balance");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              Stress Tests with Stateful Fuzzing            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function test_dosMassOperations(uint96 iterations) external {
        uint256 startGas = gasleft();

        for (uint96 i = 0; i < iterations; i++) {
            address user = makeAddr(string(abi.encodePacked("user", i)));
            uint256 amount = 1 wei;

            if (i % 2 == 0) {
                handler_stake(amount, user);
            } else {
                handler_withdraw(amount, user);
            }
        }

        uint256 gasUsed = startGas - gasleft();
        assertLt(gasUsed, 15_000_000, "DOS: Gas consumption too high");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    Helper Functions                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // function getActiveUsers() internal view returns (address[] memory) {
    //     return new address Replace with active user tracking mechanism
    // }
}