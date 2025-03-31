// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "src/Malo.sol";
// import "./simulation/Reenterer.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract MockToken is ERC20 {
//     address payable public reenterer;

//     constructor() ERC20("Mock Token", "MTK") {
//         _mint(msg.sender, 1000000e18);
//     }

//     function setReenterer(address payable _reenterer) external {
//         reenterer = _reenterer;
//     }

//     function transfer(address to, uint256 amount) public virtual override returns (bool) {
//         bool success = super.transfer(to, amount);
//         if (reenterer != address(0) && to == reenterer) {
//             try Reenterer(reenterer).triggerReentrancy() {} catch {}
//         }
//         return success;
//     }
// }

// contract MALOTest is Test {
//     MALO malo;
//     MockToken stakingToken;
//     MockToken malToken;
//     Reenterer reenterer;

//     address admin = address(0x1);
//     address user = address(0x3);

//     function setUp() public {
//         vm.startPrank(admin);

//         stakingToken = new MockToken();
//         malToken = new MockToken();
//         malo = new MALO(address(stakingToken), address(malToken), admin, admin);
//         reenterer = new Reenterer();

//         stakingToken.transfer(address(reenterer), 10000e18);
//         stakingToken.transfer(user, 10000e18);
//         malToken.transfer(address(malo), 10000e18);

//         malToken.approve(address(malo), 10000e18);
//         malo.notifyRewardAmount(7000e18);

//         // Explicitly cast address to address payable
//         stakingToken.setReenterer(payable(address(reenterer)));
//         malToken.setReenterer(payable(address(reenterer)));

//         vm.stopPrank();
//     }

//     function testWithdrawReentrancy() public {
//         // Setup attacker's stake
//         vm.startPrank(address(reenterer));
//         stakingToken.approve(address(malo), 2000e18); // Increased approval
//         malo.stake(2000e18); // Stake more for multiple withdrawals
//         vm.stopPrank();

//         // Prepare reentrant call for smaller withdrawal
//         bytes memory withdrawCall = abi.encodeWithSignature("withdraw(uint256)", 500e18);
//         reenterer.prepare(
//             address(malo),
//             0,
//             withdrawCall,
//             abi.encodeWithSignature("ReentrancyGuard: reentrant call"),
//             2 // Allow 1 reentrancy attempt
//         );

//         // Verify initial state
//         uint256 initialBalance = stakingToken.balanceOf(address(reenterer));
//         assertEq(malo.totalStaked(), 2000e18, "Initial stake incorrect");

//         // Trigger initial withdrawal (will attempt reentrancy)
//         vm.startPrank(address(reenterer));
//         malo.withdraw(1000e18); // Withdraw half initially

//         // Verify final state
//         uint256 finalBalance = stakingToken.balanceOf(address(reenterer));
//         assertEq(finalBalance, initialBalance, "Balance changed unexpectedly");
//         assertEq(malo.totalStaked(), 2000e18, "Stake changed after reentrancy");
//         vm.stopPrank();
//     }

//     function testClaimRewardsReentrancy() public {
//         // Setup rewards
//         vm.warp(block.timestamp + 7 days);

//         vm.startPrank(address(reenterer));
//         stakingToken.approve(address(malo), 1000e18);
//         malo.stake(1000e18);
//         vm.stopPrank();

//         // Prepare reward claim reentrancy
//         bytes memory claimCall = abi.encodeWithSignature("claimRewards()");
//         reenterer.prepare(address(malo), 0, claimCall, abi.encodeWithSignature("ReentrancyGuard: reentrant call"), 1);

//         // Trigger initial claim
//         vm.startPrank(address(reenterer));
//         vm.expectRevert("ReentrancyGuard: reentrant call");
//         malo.claimRewards();
//         vm.stopPrank();

//         // Verify no rewards claimed
//         assertEq(malToken.balanceOf(address(reenterer)), 0, "Rewards claimed during reentrancy");
//     }
// }
