// // SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

// import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
// import {BeforeAfter} from "../BeforeAfter.sol";
// import {Properties} from "../Properties.sol";
// import {IHevm as vm} from "@chimera/Hevm.sol";
// import {Staking} from "src/Staking.sol";

// abstract contract AdminTargets is BaseTargetFunctions, Properties {
//     address public immutable DEFAULT_GOVERNANCE;

//     constructor(address _staking, address _stakingToken, address _defaultGovernance)
//         Properties(_staking, _stakingToken)
//     {
//         DEFAULT_GOVERNANCE = _defaultGovernance;
//     }

//     // Modifier to simulate admin calls
//     modifier asAdmin() {
//         vm.prank(DEFAULT_GOVERNANCE);
//         _;
//     }

//     // Example admin handler with state tracking
//     function handler_setRewardRate(uint256 newRate) public asAdmin updateGhosts {
//         staking.setRewardRate(newRate);
//     }

//     // Additional admin functions
//     function handler_setProtocolFee(uint256 newFee) public asAdmin updateGhosts {
//         require(newFee <= staking.MAX_FEE(), "FEE_01");
//         staking.setProtocolFee(newFee);
//     }

//     function handler_pauseProtocol() public asAdmin updateGhosts {
//         staking.pause();
//     }

//     function handler_unpauseProtocol() public asAdmin updateGhosts {
//         staking.unpause();
//     }
// }
