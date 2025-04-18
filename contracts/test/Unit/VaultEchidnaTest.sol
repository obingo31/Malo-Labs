// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Vault {
    uint256 public totalAssets;
    uint256 public totalShares;

    function deposit(
        uint256 assets
    ) public returns (uint256 shares) {
        if (totalAssets == 0) {
            shares = assets;
            totalAssets = assets;
            totalShares = shares;
            return shares;
        }
        shares = (assets * totalShares) / totalAssets;
        totalAssets += assets;
        totalShares += shares;
    }

    function mint(
        uint256 shares
    ) public returns (uint256 assets) {
        if (totalShares == 0) {
            assets = shares;
            totalAssets = assets;
            totalShares = shares;
            return assets;
        }
        assets = (shares * totalAssets) / totalShares;
        totalAssets += assets;
        totalShares += shares;
    }
}

contract VaultEchidnaTest {
    Vault vault;

    constructor() {
        vault = new Vault();
        // Initialize with vulnerable state using deposit pattern
        vault.deposit(3 ether); // totalAssets=3, totalShares=3
        vault.mint(1 ether); // Forces ratio change: 3/3 -> 4/4 (maintains 1:1)

        // Now deposit again to create non-integer ratio
        vault.deposit(3 ether); // totalAssets=6, totalShares=6 + (3*6)/6 = 6+3=9
    }

    function testMintRatioDegradation() public {
        // Current state: totalAssets=6, totalShares=9 (ratio 0.666...)
        uint256 beforeRatio = vault.totalAssets() * 1e18 / vault.totalShares();

        // Mint operation that will demonstrate the bug
        vault.mint(3); // assets = (3 * 6)/9 = 2 (exact division)
        // New totalAssets = 6+2=8
        // New totalShares = 9+3=12
        // New ratio = 8/12 = 0.666... (same ratio)

        // Now mint 1 share with truncation
        vault.mint(1); // assets = (1 * 8)/12 = 0 (truncated from 0.666...)
        // New totalAssets = 8+0=8
        // New totalShares = 12+1=13
        uint256 afterRatio = vault.totalAssets() * 1e18 / vault.totalShares();

        // Final ratio = 8/13 ≈ 0.615 < 0.666...
        assert(afterRatio >= beforeRatio); // This will fail
    }
}
