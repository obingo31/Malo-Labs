// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// // Libraries
// import "forge-std/Test.sol";
// import "forge-std/console.sol";

// // Contracts
// import {Invariants} from "./Invariants.t.sol";
// // import {Setup} from "./Setup.t.sol";
// // import {ISiloConfig} from "silo-core/contracts/SiloConfig.sol";
// // import {MockSiloOracle} from "./utils/mocks/MockSiloOracle.sol";
// import {IStaker} from "src/interfaces/IStaker.sol";
// import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

// /*
//  * Test suite that converts from  "fuzz tests" to foundry "unit tests"
//  * The objective is to go from random values to hardcoded values that can be analyzed more easily
//  */
// contract CryticToFoundry is Invariants {
//     CryticToFoundry Tester = this;
//     uint256 constant DEFAULT_TIMESTAMP = 337812;

//     modifier setup() override {
//         targetActor = address(actor);
//         _;
//         targetActor = address(0);
//     }

//     function setUp() public {
//         // Deploy core protocol contracts
//         _deployCore();
        
//         // Set up actors with balances and approvals
//         _setupActors();
//         _initializeActorBalances();
        
//         // Initialize any handler contracts
//         _setUpHandlers();

//         /// @dev fixes the actor to the first user
//         actor = actors[USER1];

//         vm.warp(DEFAULT_TIMESTAMP);
//     }

//     /// @dev Needed in order for foundry to recognise the contract as a test, faster debugging
//     function testAux() public {}

//     ///////////////////////////////////////////////////////////////////////////////////////////////
//     //                                FAILING INVARIANTS REPLAY                                  //
//     ///////////////////////////////////////////////////////////////////////////////////////////////

//     function test_replayechidna_BASE_INVARIANT() public {
//         Tester.setOraclePrice(154174253363420274135519693994558375770505353341038094319633, 1);
//         Tester.setOraclePrice(117361312846819359113791019924540616345894207664659799350103, 0);
//         Tester.mint(1025, 0, 1, 0);
//         Tester.deposit(1, 0, 0, 1);
//         Tester.borrowShares(1, 0, 0);
//         echidna_BASE_INVARIANT();
//         Tester.setOraclePrice(1, 1);
//         echidna_BASE_INVARIANT();
//     }


//     function test_replayechidna_BASE_INVARIANT2() public {
//         Tester.mint(1, 0, 1, 1);
//         Tester.deposit(1, 0, 1, 1);
//         Tester.assert_LENDING_INVARIANT_B(1, 1);
//         echidna_BASE_INVARIANT();
//     }



//     ///////////////////////////////////////////////////////////////////////////////////////////////
//     //                              FAILING POSTCONDITIONS REPLAY                                //
//     ///////////////////////////////////////////////////////////////////////////////////////////////

//     function test_borrowSameAssetEchidna() public {
//         this.mint(2006, 0, 0, 1);
//         this.borrowSameAsset(1, 0, 0);
//     }

//     function test_depositEchidna() public {
//         Tester.deposit(1, 0, 0, 0);
//     }

//     function test_flashLoanEchidna() public {
//         Tester.flashLoan(1, 76996216303583, 0, 0);
//     }

//     function test_transitionCollateralEchidna() public {
//         Tester.transitionCollateral(0, 0, 0, 0);
//     }

    
//         // Max Withdraw 

    

//     function test_replayTesterassertBORROWING_HSPOST_F2() public {
//         Tester.mint(40422285801235863700109, 1, 1, 0); // Deposit on Silo 1 for ACTOR2
//         Tester.deposit(2, 0, 0, 1); // Deposit on Silo 0 for ACTOR1
//         Tester.assertBORROWING_HSPOST_F(1, 0); // ACTOR tries to maxBorrow on Silo 0
//     }


//     ///////////////////////////////////////////////////////////////////////////////////////////////
//     //                                 POSTCONDITIONS: FINAL REVISION                            //
//     ///////////////////////////////////////////////////////////////////////////////////////////////

//     function test_replayflashLoan() public {
//         Tester.flashLoan(0, 0, 0, 0);
//     }

    

//     ///////////////////////////////////////////////////////////////////////////////////////////////
//     //                                           HELPERS                                         //
//     ///////////////////////////////////////////////////////////////////////////////////////////////

//     /// @notice Fast forward the time and set up an actor,
//     /// @dev Use for ECHIDNA call-traces
//     function _delay(uint256 _seconds) internal {
//         vm.warp(block.timestamp + _seconds);
//     }

//     /// @notice Set up an actor
//     function _setUpActor(address _origin) internal {
//         actor = actors[_origin];
//     }

//     /// @notice Set up an actor and fast forward the time
//     /// @dev Use for ECHIDNA call-traces
//     function _setUpActorAndDelay(address _origin, uint256 _seconds) internal {
//         actor = actors[_origin];
//         vm.warp(block.timestamp + _seconds);
//     }

//     /// @notice Set up a specific block and actor
//     function _setUpBlockAndActor(uint256 _block, address _user) internal {
//         vm.roll(_block);
//         actor = actors[_user];
//     }

//     /// @notice Set up a specific timestamp and actor
//     function _setUpTimestampAndActor(uint256 _timestamp, address _user) internal {
//         vm.warp(_timestamp);
//         actor = actors[_user];
//     }
// }