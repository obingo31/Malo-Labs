// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Vault {
    uint256 public totalAssets;
    uint256 public totalShares;

    function deposit(
        uint256 assets
    ) public returns (uint256 shares) {
        shares = (assets * totalShares) / totalAssets;

        totalAssets += assets;
        totalShares += shares;
    }

    function mint(
        uint256 shares
    ) public returns (uint256 assets) {
        assets = (shares * totalAssets) / totalShares;

        totalAssets += assets;
        totalShares += shares;
    }
}
