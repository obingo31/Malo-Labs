// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ExpectedErrors} from "./ExpectedErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {Properties} from "./Properties.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Staking} from "src/Staking.sol";

contract TargetFunctions is Properties, BaseTargetFunctions, ExpectedErrors {
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
    /*         Handler Functions with Precondition Checks         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function handler_stake(uint256 amount, address user) external checkExpectedErrors("Stake") {
        // Precondition checks
        require(amount > 0, "Amount must be positive");
        require(stakingToken.balanceOf(user) >= amount, "Insufficient user balance");
        require(stakingToken.allowance(user, address(staking)) >= amount, "Insufficient allowance");

        uint256 preTotal = staking.totalStaked();
        uint256 preBalance = stakingToken.balanceOf(address(staking));

        vm.prank(user);
        staking.stake(amount);

        // HSPOST: Immediate state validation
        assertEq(staking.balanceOf(user), preBalance + amount, "HSPOST: User balance mismatch");
        assertEq(staking.totalStaked(), preTotal + amount, "HSPOST: Total staked mismatch");
        assertEq(stakingToken.balanceOf(address(staking)), preBalance + amount, "HSPOST: Contract balance mismatch");
    }

    function handler_withdraw(uint256 amount, address user) external checkExpectedErrors("Withdraw") {
        // Precondition checks
        require(amount > 0, "Amount must be positive");
        require(staking.balanceOf(user) >= amount, "Insufficient staked balance");
        require(stakingToken.balanceOf(address(staking)) >= amount, "Insufficient contract liquidity");

        uint256 preTotal = staking.totalStaked();
        uint256 preBalance = stakingToken.balanceOf(address(staking));

        vm.prank(user);
        staking.withdraw(amount);

        // HSPOST: Immediate state validation
        assertEq(staking.balanceOf(user), preBalance - amount, "HSPOST: User balance mismatch");
        assertEq(staking.totalStaked(), preTotal - amount, "HSPOST: Total staked mismatch");
        assertEq(stakingToken.balanceOf(address(staking)), preBalance - amount, "HSPOST: Contract balance mismatch");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               Global Postconditions (GPOST)                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function checkGlobalPostconditions() external view {
        // GPOST 1: Sum of balances matches total supply
        uint256 sumBalances;
        address[] memory users = getActiveUsers();
        for (uint256 i = 0; i < users.length; i++) {
            sumBalances += staking.balanceOf(users[i]);
        }
        assertEq(sumBalances, staking.totalStaked(), "GPOST: Balance sum mismatch");

        // GPOST 2: Contract token balance matches total supply
        assertEq(stakingToken.balanceOf(address(staking)), staking.totalStaked(), "GPOST: Contract balance mismatch");

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

            // Alternate between stake and withdraw
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

    function getActiveUsers() internal view returns (address[] memory) {
        // Implementation depends on your user tracking setup
        return new address[](0);
    }
}
