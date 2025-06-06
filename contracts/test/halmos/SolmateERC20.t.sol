// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {ERC20Test} from "../mocks/ERC20Test.sol";
import {SolmateERC20} from "../mocks/SolmateERC20.sol";

/**
 * @notice Forked from: https://github.com/a16z/halmos/blob/main/examples/tokens/ERC20/test/ERC20Test.sol.
 */
/// @custom:halmos --solver-timeout-assertion 0
contract SolmateERC20Test is ERC20Test {
    /// @custom:halmos --solver-timeout-branching 1000
    function setUp() public override {
        address deployer = address(0x1000);

        SolmateERC20 token_ = new SolmateERC20("SolmateERC20", "SolmateERC20", 18, 1_000_000_000e18, deployer);
        token = address(token_);

        holders = new address[](3);
        holders[0] = address(0x1001);
        holders[1] = address(0x1002);
        holders[2] = address(0x1003);

        for (uint256 i = 0; i < holders.length; i++) {
            address account = holders[i];
            uint256 balance = svm.createUint256("balance");
            vm.prank(deployer);
            token_.transfer(account, balance);
            for (uint256 j = 0; j < i; j++) {
                address other = holders[j];
                uint256 amount = svm.createUint256("amount");
                vm.prank(account);
                token_.approve(other, amount);
            }
        }
    }

    function check_NoBackdoor(bytes4 selector, address caller, address other) public {
        bytes memory args = svm.createBytes(1024, "data");
        _checkNoBackdoor(selector, args, caller, other);
    }
}

//  halmos --function test
