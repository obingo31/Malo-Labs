// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// abstract contract Ghosts is BeforeAfter {
//     struct StakingVars {
//         uint256 totalStaked;
//         uint256 totalRewards;
//         uint256 protocolFees;
//         uint256 lastUpdateTime;
//         uint256 periodFinish;
//         mapping(address => uint256) userStakes;
//         mapping(address => uint256) userRewards;
//     }

//     StakingVars internal _ghostBefore;
//     StakingVars internal _ghostAfter;

//     modifier trackState() {
//         _snapshot(_ghostBefore);
//         _;
//         _snapshot(_ghostAfter);
//     }

//     function _snapshot(StakingVars storage vars) internal virtual;
//     function _updateUserState(address user) internal virtual;

//     // Ghost state transitions
//     function _ghostStake(address user, uint256 amount) internal {
//         _ghostAfter.totalStaked += amount;
//         _ghostAfter.userStakes[user] += amount;
//     }

//     function _ghostWithdraw(address user, uint256 amount) internal {
//         _ghostAfter.totalStaked -= amount;
//         _ghostAfter.userStakes[user] -= amount;
//     }

//     function _ghostClaim(address user) internal virtual;

//     // Utility for tests
//     function _getActors() internal view virtual returns (address[] memory);
// }
