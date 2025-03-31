// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import {Vm} from "forge-std/Vm.sol";

// import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "src/Malo.sol";

// /**
//  * @title MALOWithdrawDosTester
//  * @dev Specialized DoS testing contract for MALO staking contract focusing on:
//  * - Withdrawal function vulnerability testing
//  * - Reward claiming DoS protection
//  * - Fee mechanism analysis
//  * - Lock period enforcement
//  */
// contract MALOWithdrawDosTester {
//     // Common withdrawal error selectors
//     bytes4[] public WITHDRAW_ERRORS;

//     // MALO-specific error selectors
//     bytes4 public constant ZERO_AMOUNT_ERROR = bytes4(keccak256("Cannot stake 0"));
//     bytes4 public constant INVALID_AMOUNT_ERROR = bytes4(keccak256("Invalid amount"));
//     bytes4 public constant NO_REWARDS_ERROR = bytes4(keccak256("No rewards"));
//     bytes4 public constant VESTING_ACTIVE_ERROR = bytes4(keccak256("Vesting active"));

//     MALO public maloContract;

//     constructor(address _maloContract) {
//         maloContract = MALO(_maloContract);

//         // Initialize standard expected withdrawal errors
//         WITHDRAW_ERRORS.push(IERC20Errors.ERC20InsufficientBalance.selector);
//         WITHDRAW_ERRORS.push(ZERO_AMOUNT_ERROR);
//         WITHDRAW_ERRORS.push(INVALID_AMOUNT_ERROR);
//         WITHDRAW_ERRORS.push(NO_REWARDS_ERROR);
//         WITHDRAW_ERRORS.push(VESTING_ACTIVE_ERROR);
//     }

//     /**
//      * @dev Test a withdrawal function for DOS vulnerabilities
//      * @param target Contract to test (MALO contract address)
//      * @param callData Function call data (withdraw or claimRewards)
//      * @param balanceCheck Function to verify sufficient balance
//      * @param expectedError Specific error expected (0 for none)
//      * @return isVulnerable True if unexpected revert occurs
//      * @return gasUsed Gas consumed by the operation
//      * @return isReentrant True if reentrancy detected
//      */
//     function testWithdrawDos(
//         address target,
//         bytes memory callData,
//         function(address) external view returns(bool) balanceCheck,
//         bytes4 expectedError
//     ) external returns (
//         bool isVulnerable,
//         uint256 gasUsed,
//         bool isReentrant
//     ) {
//         // Verify preconditions
//         require(balanceCheck(target), "Preconditions not met");

//         uint256 gasStart = gasleft();
//         (bool success, bytes memory result) = target.call(callData);
//         gasUsed = gasStart - gasleft();

//         // Check for expected successful execution
//         if (success) {
//             return (false, gasUsed, false);
//         }

//         // Check for expected errors
//         if (expectedError != bytes4(0)) {
//             if (result.length >= 4 && bytes4(result) == expectedError) {
//                 return (false, gasUsed, false);
//             }
//         }

//         // Check against whitelisted common errors
//         if (result.length >= 4) {
//             bytes4 receivedError = bytes4(result);
//             for (uint i = 0; i < WITHDRAW_ERRORS.length; i++) {
//                 if (receivedError == WITHDRAW_ERRORS[i]) {
//                     return (false, gasUsed, false);
//                 }
//             }
//         }

//         // Check for reentrancy (using call depth tracking)
//         uint256 callDepth;
//         assembly {
//             // Note: The actual implementation would use a mechanism like
//             // callDepth := sload(0) // A storage variable tracking depth
//             callDepth := 1 // Simplified for example purposes
//         }
//         isReentrant = callDepth > 1;

//         return (true, gasUsed, isReentrant);
//     }

//     /**
//      * @dev Add custom error signature to the whitelist
//      */
//     function addAllowedError(bytes4 errorSelector) external {
//         WITHDRAW_ERRORS.push(errorSelector);
//     }

//     /**
//      * @dev Test MALO's withdraw function with various amounts
//      */
//     function testMALOWithdrawAmount(address user, uint256[] memory amounts) external returns (
//         bool[] memory isVulnerable,
//         uint256[] memory gasUsed
//     ) {
//         isVulnerable = new bool[](amounts.length);
//         gasUsed = new uint256[](amounts.length);
//         bool isReentrant;

//         for (uint i = 0; i < amounts.length; i++) {
//             bytes memory callData = abi.encodeWithSelector(
//                 MALO.withdraw.selector,
//                 amounts[i]
//             );

//             (isVulnerable[i], gasUsed[i], isReentrant) = this.testWithdrawDos(
//                 address(maloContract),
//                 callData,
//                 this.hasMALOStake,
//                 bytes4(0) // No specific expected error
//             );
//         }
//     }

//     /**
//      * @dev Test MALO's claimRewards function with various timing conditions
//      */
//     function testMALOClaimRewards(address user, uint256[] memory timeOffsets) external returns (
//         bool[] memory isVulnerable,
//         uint256[] memory gasUsed
//     ) {
//         isVulnerable = new bool[](timeOffsets.length);
//         gasUsed = new uint256[](timeOffsets.length);
//         bool isReentrant;

//         bytes memory callData = abi.encodeWithSelector(MALO.claimRewards.selector);

//         for (uint i = 0; i < timeOffsets.length; i++) {
//             // Set block.timestamp to test different vesting periods
//             vm.warp(block.timestamp + timeOffsets[i]);

//             (isVulnerable[i], gasUsed[i], isReentrant) = this.testWithdrawDos(
//                 address(maloContract),
//                 callData,
//                 this.hasMALORewards,
//                 bytes4(0) // No specific expected error
//             );
//         }
//     }

//     /**
//      * @dev Helper function to check MALO staked balance preconditions
//      */
//     function hasMALOStake(address account) external view returns (bool) {
//         return maloContract.totalStaked() > 0;
//     }

//     /**
//      * @dev Helper function to check MALO rewards preconditions
//      */
//     function hasMALORewards(address account) external view returns (bool) {
//         return maloContract.earned(msg.sender) > 0;
//     }

//     /**
//      * @dev Test fee calculation accuracy across different amounts
//      */
//     function testFeeCalculation(uint256[] memory amounts) external view returns (
//         uint256[] memory fees,
//         uint256[] memory netAmounts
//     ) {
//         fees = new uint256[](amounts.length);
//         netAmounts = new uint256[](amounts.length);

//         for (uint i = 0; i < amounts.length; i++) {
//             uint256 fee = (amounts[i] * maloContract.withdrawalFeeBps()) / 1000;
//             fees[i] = fee;
//             netAmounts[i] = amounts[i] - fee;
//         }
//     }

//     /**
//      * @dev Generate a comprehensive report on withdrawal conditions
//      */
//     function generateWithdrawalReport(address user) external view returns (
//         uint256 totalStaked,
//         uint256 userBalance,
//         uint256 pendingRewards,
//         uint256 timeUntilUnlock,
//         uint256 estimatedFee
//     ) {
//         totalStaked = maloContract.totalStaked();
//         userBalance = 0; // Need to handle this through a different mechanism since _balances is private
//         pendingRewards = maloContract.earned(user);

//         // Calculate time until claim is unlocked
//         uint256 vestingStart = maloContract.vestingStart(user);
//         uint256 lockPeriod = maloContract.claimLockPeriod();
//         timeUntilUnlock = vestingStart + lockPeriod > block.timestamp ?
//                          vestingStart + lockPeriod - block.timestamp : 0;

//         // Estimate withdrawal fee
//         estimatedFee = (userBalance * maloContract.withdrawalFeeBps()) / 1000;
//     }

//     // Cheatcode interface for time manipulation
//     function vm() internal view returns (address) {
//         return address(uint160(uint256(keccak256("hevm cheat code"))));
//     }
// }

// /**
//  * @title MALOWithdrawDosTestHelper
//  * @dev Helper functions for MALO withdrawal checks
//  */
// contract MALOWithdrawDosTestHelper {
//     MALO public maloContract;

//     constructor(address _maloContract) {
//         maloContract = MALO(_maloContract);
//     }

//     /**
//      * @dev Prepare conditions for testing - stake tokens
//      */
//     function prepareStake(address token, uint256 amount) external {
//         IERC20(token).approve(address(maloContract), amount);
//         maloContract.stake(amount);
//     }

//     /**
//      * @dev Prepare conditions for testing - add rewards
//      */
//     function prepareRewards(address token, uint256 amount) external {
//         // Must be called by an account with REWARDS_ADMIN_ROLE
//         IERC20(token).approve(address(maloContract), amount);
//         maloContract.notifyRewardAmount(amount);
//     }

//     /**
//      * @dev Check if stake withdrawal is possible
//      */
//     function canWithdraw(address user, uint256 amount) external view returns (bool) {
//         // We'd need access to the private _balances mapping for a complete check
//         // This is a simplified version
//         return maloContract.totalStaked() >= amount;
//     }

//     /**
//      * @dev Check if rewards can be claimed
//      */
//     function canClaimRewards(address user) external view returns (bool) {
//         uint256 earned = maloContract.earned(user);
//         uint256 vestingStart = maloContract.vestingStart(user);
//         uint256 claimLock = maloContract.claimLockPeriod();

//         return earned > 0 && block.timestamp >= vestingStart + claimLock;
//     }
// }
