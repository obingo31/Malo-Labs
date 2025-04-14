// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// import {ERC20Test} from "../mocks/ERC20Test.sol";
// import {Vault} from "../mocks/Vault.sol";

// contract VaultTest is Test {
//     Vault vault;

//     constructor() {
//         vault = new Vault();
//     }

//     // Generic clamp function from example
//     function clampLte(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a > b ? b : a;
//     }

//     // Test deposit function with same pattern as example
//     function testDeposit(uint256 _assets) public {
//         uint256 assets = clampLte(_assets, type(uint128).max);

//         uint256 preShares = vault.totalShares();
//         uint256 preAssets = vault.totalAssets();

//         vault.deposit(assets);

//         // Post-conditions
//         if (preShares == 0) {
//             // First deposit initializes 1:1 ratio
//             assertEq(vault.totalShares(), assets);
//             assertEq(vault.totalAssets(), assets);
//         } else {
//             uint256 expectedShares = (assets * preShares) / preAssets;
//             assertEq(vault.totalShares(), preShares + expectedShares);
//             assertEq(vault.totalAssets(), preAssets + assets);
//         }
//     }

//     // Test mint function with same structure
//     function testMint(uint256 _shares) public {
//         // Ensure vault is initialized first
//         if (vault.totalShares() == 0) {
//             vault.deposit(1); // Bootstrap with minimal deposit
//         }

//         uint256 shares = clampLte(_shares, type(uint128).max);
//         uint256 preAssets = vault.totalAssets();
//         uint256 preShares = vault.totalShares();

//         vault.mint(shares);

//         // Post-condition: Asset/share ratio should not decrease
//         uint256 preRatio = preAssets * 1e18 / preShares;
//         uint256 postRatio = vault.totalAssets() * 1e18 / vault.totalShares();
//         assertGe(postRatio, preRatio); // This will fail naturally
//     }
// }
