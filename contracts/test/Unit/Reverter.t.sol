// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Setup} from "../InvariantTests/Setup.sol";
import {MALGovernanceStaking} from "src/MALGovernanceStaking.sol";
import {MockVotesToken} from "../InvariantTests/MockVotesToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract Reverter {
    fallback() external {
        revert("Reverter: I am a contract that always reverts");
    }
}

contract ReverterWithDecimals is Reverter {
    function decimals() external pure returns (uint8) {
        return 18;
    }
}

contract MALGovernanceStakingFuzzer is Test, Setup {
    Reverter public reverter;
    ReverterWithDecimals public reverterWithDecimals;

    bool public proposalExecutionFailed;

    function setUp() public {
        setup();
        reverter = new Reverter();
        reverterWithDecimals = new ReverterWithDecimals();
    }

    function testFuzz_ExecuteProposalWithReverter(
        bytes calldata proposalData,
        uint256 stakeAmount,
        uint256 votingPeriod
    ) public {
        stakeAmount = bound(stakeAmount, 100 ether, 10_000 ether);
        votingPeriod = bound(votingPeriod, 1 hours, 30 days);

        vm.startPrank(daoMultisig);
        malGovernanceStaking.updateVotingPeriod(votingPeriod);
        vm.stopPrank();

        address actor = _currentActor();
        vm.startPrank(actor);
        IERC20(governanceToken).approve(address(malGovernanceStaking), stakeAmount);
        malGovernanceStaking.stake(stakeAmount);

        uint256 proposalId = malGovernanceStaking.createProposal(address(reverter), proposalData);
        malGovernanceStaking.vote(proposalId, true);
        vm.stopPrank();

        vm.warp(block.timestamp + votingPeriod + 1);

        vm.startPrank(actor);
        try malGovernanceStaking.executeProposal(proposalId) {
            proposalExecutionFailed = false;
        } catch {
            proposalExecutionFailed = true;
        }
        vm.stopPrank();

        (,,,,,,, bool executed) = malGovernanceStaking.proposals(proposalId);
        assert(proposalExecutionFailed);
        assert(!executed);
    }

    function testFuzz_ExecutionFailureHandling(bytes calldata callData, bool useDecimalReverter) public {
        address target = useDecimalReverter ? address(reverterWithDecimals) : address(reverter);
        uint256 stakeAmount = 20_000 ether;
        address actor = _currentActor();

        vm.startPrank(actor);
        IERC20(governanceToken).approve(address(malGovernanceStaking), stakeAmount);
        malGovernanceStaking.stake(stakeAmount);

        uint256 proposalId = malGovernanceStaking.createProposal(target, callData);
        malGovernanceStaking.vote(proposalId, true);
        vm.stopPrank();

        vm.warp(block.timestamp + malGovernanceStaking.votingPeriod() + 1);

        vm.startPrank(actor);
        try malGovernanceStaking.executeProposal(proposalId) {
            fail();
        } catch (bytes memory reason) {
            bytes4 expectedSelector = bytes4(keccak256("ExecutionFailed()"));
            bytes4 receivedSelector = bytes4(reason);
            assertEq(expectedSelector, receivedSelector);
        }
        vm.stopPrank();

        (,,,,,,, bool executed) = malGovernanceStaking.proposals(proposalId);
        assert(!executed);
    }
}

//  forge test --match-test testFuzz_ExecuteProposalWithReverter -vvvv
