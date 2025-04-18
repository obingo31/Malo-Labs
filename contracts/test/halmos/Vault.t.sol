// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {SymTest} from "halmos-cheatcodes/SymTest.sol";

import {Vault} from "../mocks/Vault.sol";

contract VaultMock is Vault {
    function setTotalAssets(
        uint256 _totalAssets
    ) public {
        totalAssets = _totalAssets;
    }

    function setTotalShares(
        uint256 _totalShares
    ) public {
        totalShares = _totalShares;
    }
}

// forked from https://github.com/a16z/halmos/blob/main/examples/simple/test/Vault.t.sol
/// @custom:halmos --solver-timeout-assertion 0
contract VaultTest is SymTest {
    VaultMock vault;

    function setUp() public {
        vault = new VaultMock();

        vault.setTotalAssets(svm.createUint256("A1"));
        vault.setTotalShares(svm.createUint256("S1"));
    }

    /// need to set a timeout for this test, the solver can run for hours
    /// @custom:halmos --solver-timeout-assertion 10000
    function check_deposit(
        uint256 assets
    ) public {
        uint256 A1 = vault.totalAssets();
        uint256 S1 = vault.totalShares();

        vault.deposit(assets);

        uint256 A2 = vault.totalAssets();
        uint256 S2 = vault.totalShares();

        // assert(A1 / S1 <= A2 / S2);
        assert(A1 * S2 <= A2 * S1); // no counterexample
    }

    function check_mint(
        uint256 shares
    ) public {
        uint256 A1 = vault.totalAssets();
        uint256 S1 = vault.totalShares();

        vault.mint(shares);

        uint256 A2 = vault.totalAssets();
        uint256 S2 = vault.totalShares();

        // assert(A1 / S1 <= A2 / S2);
        assert(A1 * S2 <= A2 * S1); // counterexamples exist
    }
}
