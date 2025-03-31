// // SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

// import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
// // import {Properties} from "../Properties.sol";
// // import {vm} from "@chimera/Hevm.sol";

// import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

// abstract contract ManagersTargets is BaseTargetFunctions, Properties {
//     function switchActor(uint256 entropy) public returns (address) {
//         _switchActor(entropy);

//         return _getActor();
//     }

//     function switch_asset(uint256 entropy) public returns (address) {
//         _switchAsset(entropy);

//         return _getAsset();
//     }

//     function add_new_asset() public returns (address) {
//         address newAsset = _newAsset();
//         return newAsset;
//     }

//     //     function asset_approve(address to, uint128 amt) public updateGhosts asActor {
//     //         MockERC20(_getAsset()).approve(to, amt);
//     //     }

//     //     function asset_mint(address to, uint128 amt) public updateGhosts asAdmin {
//     //         MockERC20(_getAsset()).mint(to, amt);
//     //     }

//     //     function _getActors() internal view override(Properties, ActorManager) returns (address[] memory) {
//     //         return actors;
//     //     }
// }
