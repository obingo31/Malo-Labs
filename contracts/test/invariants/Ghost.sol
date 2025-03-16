// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Staking} from "src/Staking.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Properties} from "./Properties.sol";

contract Ghost is Properties {
    // Tracked protocol ghost state
    struct GhostState {
        uint256 totalStakedGhost;
        uint256 totalRewardsGhost;
        uint256 protocolFeesGhost;
        mapping(address => uint256) userStakedGhost;
        mapping(address => uint256) userRewardsGhost;
        mapping(address => uint256) lastUpdateGhost;
    }

    GhostState private ghost;
    MaloStaking private staking;
    IERC20 private stakingToken;
    IERC20 private rewardToken;

    // Snapshot tracking
    struct Snapshot {
        uint256 totalStaked;
        uint256 totalRewards;
        uint256 protocolFees;
    }

    Snapshot private preOpSnapshot;

    constructor(MaloStaking _staking, IERC20 _stakingToken, IERC20 _rewardToken) {
        staking = _staking;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      TEST HOOKS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _beforeEach() internal {
        ghost.totalStakedGhost = staking.totalStaked();
        ghost.totalRewardsGhost = staking.totalRewards();
        ghost.protocolFeesGhost = 0;

        // Reset user tracking
        address[] memory users = getActors();
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            ghost.userStakedGhost[user] = staking.balanceOf(user);
            ghost.userRewardsGhost[user] = staking.earned(user);
            ghost.lastUpdateGhost[user] = block.timestamp;
        }

        _snapshotState();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      GHOST OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function ghostStake(address user, uint256 amount) external {
        ghost.userStakedGhost[user] += amount;
        ghost.totalStakedGhost += amount;
        _updateUserRewards(user);
    }

    function ghostWithdraw(address user, uint256 amount) external {
        ghost.userStakedGhost[user] -= amount;
        ghost.totalStakedGhost -= amount;
        _updateUserRewards(user);
    }

    function ghostClaim(address user) external {
        uint256 rewards = ghost.userRewardsGhost[user];
        uint256 fee = (rewards * staking.protocolFee()) / 10000;

        ghost.userRewardsGhost[user] = 0;
        ghost.totalRewardsGhost -= rewards;
        ghost.protocolFeesGhost += fee;
        _updateUserRewards(user);
    }

    function ghostEmergencyWithdraw(address user) external {
        uint256 amount = ghost.userStakedGhost[user];
        ghost.userStakedGhost[user] = 0;
        ghost.totalStakedGhost -= amount;
        ghost.userRewardsGhost[user] = 0;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INVARIANTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function invariant_totalStaked() external view {
        assertEq(staking.totalStaked(), ghost.totalStakedGhost, "Total staked mismatch");
    }

    function invariant_userBalances(address user) external view {
        assertEq(staking.balanceOf(user), ghost.userStakedGhost[user], "User balance mismatch");
    }

    function invariant_rewardAccounting() external view {
        assertEq(
            staking.totalRewards(), ghost.totalRewardsGhost + ghost.protocolFeesGhost, "Reward accounting mismatch"
        );
    }

    function invariant_protocolFees() external view {
        assertEq(rewardToken.balanceOf(address(this)), ghost.protocolFeesGhost, "Protocol fee mismatch");
    }

    function invariant_emergencyWithdrawReset() external view {
        Snapshot memory current = _currentSnapshot();
        assertEq(current.totalStaked, preOpSnapshot.totalStaked, "Emergency withdraw total mismatch");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTERNAL HELPERS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _updateUserRewards(address user) private {
        uint256 timeElapsed = block.timestamp - ghost.lastUpdateGhost[user];
        if (timeElapsed > 0 && ghost.totalStakedGhost > 0) {
            uint256 reward = (ghost.userStakedGhost[user] * staking.rewardRate() * timeElapsed) / ghost.totalStakedGhost;
            ghost.userRewardsGhost[user] += reward;
            ghost.totalRewardsGhost += reward;
        }
        ghost.lastUpdateGhost[user] = block.timestamp;
    }

    function _snapshotState() private {
        preOpSnapshot = Snapshot({
            totalStaked: staking.totalStaked(),
            totalRewards: staking.totalRewards(),
            protocolFees: rewardToken.balanceOf(address(this))
        });
    }

    function _currentSnapshot() private view returns (Snapshot memory) {
        return Snapshot({
            totalStaked: staking.totalStaked(),
            totalRewards: staking.totalRewards(),
            protocolFees: rewardToken.balanceOf(address(this))
        });
    }
}
