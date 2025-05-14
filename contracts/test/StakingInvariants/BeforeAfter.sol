// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";
import {Strings, Pretty} from "./Pretty.sol";

abstract contract BeforeAfter is Setup {
    using Strings for string;
    using Pretty for uint256;
    using Pretty for bool;

    struct Vars {
        uint256 balance_actor;
        uint256 earned_actor;
        uint256 totalStaked;
        uint256 totalRewardsDistributed;
        uint256 protocolFee;
        uint256 rewardRate;
        uint256 rewardPeriod;
        address feeRecipient;
        bool paused;
    }

    Vars internal _before;
    Vars internal _after;

    modifier updateGhosts() {
        __before();
        _;
        __after();
        _validateStateConsistency();
    }

    function __before() internal {
        address actor = _getActor();
        _before = Vars({
            balance_actor: staking.balanceOf(actor),
            earned_actor: staking.earned(actor),
            totalStaked: staking.totalStaked(),
            totalRewardsDistributed: staking.totalRewardsDistributed(),
            protocolFee: staking.protocolFee(),
            rewardRate: staking.rewardRate(),
            rewardPeriod: staking.rewardPeriod(),
            feeRecipient: staking.feeRecipient(),
            paused: staking.paused()
        });
    }

    function __after() internal {
        address actor = _getActor();
        _after = Vars({
            balance_actor: staking.balanceOf(actor),
            earned_actor: staking.earned(actor),
            totalStaked: staking.totalStaked(),
            totalRewardsDistributed: staking.totalRewardsDistributed(),
            protocolFee: staking.protocolFee(),
            rewardRate: staking.rewardRate(),
            rewardPeriod: staking.rewardPeriod(),
            feeRecipient: staking.feeRecipient(),
            paused: staking.paused()
        });
    }

    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ Security Checks ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

    function _validateStateConsistency() internal view {
        // 1. Fee boundary check
        require(
            _after.protocolFee <= staking.MAX_FEE(), _formatError("Fee exceeds maximum", _after.protocolFee.pretty())
        );

        // 2. Staking token supply integrity
        require(
            _after.totalStaked <= staking.stakingToken().totalSupply(),
            _formatError("Total staked exceeds supply", _after.totalStaked.pretty())
        );

        // 3. Pause state consistency
        if (_before.paused) {
            require(_after.paused, _formatError("Unauthorized unpause", _after.paused.pretty()));
        }
    }

    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ Formatted Assertions ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

    function _formatDiff(
        string memory name,
        uint256 beforeVal,
        uint256 afterVal
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(name, " changed from ", beforeVal.pretty(), " to ", afterVal.pretty()));
    }

    function _formatError(string memory message, string memory value) internal pure returns (string memory) {
        return Strings.concat(message, value);
    }

    /// @dev Validates balance change with formatted error message
    function _assertBalanceChange(
        int256 expectedDelta
    ) internal view {
        int256 actualDelta = int256(_after.balance_actor) - int256(_before.balance_actor);
        require(actualDelta == expectedDelta, _formatDiff("Balance", _before.balance_actor, _after.balance_actor));
    }

    /// @dev Validates reward accrual with formatted error message
    function _assertRewardsIncreased() internal view {
        require(
            _after.earned_actor >= _before.earned_actor,
            _formatDiff("Rewards", _before.earned_actor, _after.earned_actor)
        );
    }

    /// @dev Validates protocol fee boundaries
    function _assertFeeBounds() internal view {
        require(
            _after.protocolFee <= staking.MAX_FEE(),
            _formatError("Protocol fee exceeds max", _after.protocolFee.pretty())
        );
    }
}
