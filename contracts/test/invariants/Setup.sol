// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

// Dependencies
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {Constants} from "./Constants.sol";
import {ExpectedErrors} from "./ExpectedErrors.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {Staking} from "src/Staking.sol";

// Managers
import {ActorManager} from "../managers/ActorManager.sol";
import {AssetManager} from "../managers/AssetManager.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Constants, ExpectedErrors {
    // Contract instances
    ERC20Mock public stakingToken;
    ERC20Mock public maloToken;
    Staking public staking;

    // Addresses for the protocol
    address public defaultGovernance;
    address public techOpsMultisig;

    constructor() {
        defaultGovernance = address(0x1111);
        techOpsMultisig = address(0x2222);
    }

    // Setup function
    function setup() internal virtual override {
        _deployContracts();
        _setupActorsAndAssets();
        _configurePermissions();
        _initializeTokenBalances();
    }

    // Deploy all required contracts
    function _deployContracts() private {
        stakingToken = new ERC20Mock("Staking Token", "STK");
        maloToken = new ERC20Mock("Malo Token", "MALO");

        staking = new Staking(
            address(stakingToken), address(maloToken), address(defaultGovernance), REWARD_EPOCH, address(this)
        );
    }

    // Setup actors and assets
    function _setupActorsAndAssets() private {
        // Initialize actors
        _addActor(ALICE);
        _addActor(BOB);
        _addActor(address(this));
        _enableActor(address(this));

        // Configure assets
        _addAsset(address(stakingToken));
        _addAsset(address(maloToken));
        _enableAsset(address(stakingToken));
    }

    // Configure role-based permissions
    function _configurePermissions() private {
        // Grant roles using governance actor
        vm.prank(address(defaultGovernance));
        staking.grantRole(staking.DEFAULT_ADMIN_ROLE(), address(techOpsMultisig));

        // Grant FEE_MANAGER_ROLE to default governance
        vm.prank(address(defaultGovernance));
        staking.grantRole(FEE_MANAGER_ROLE, address(defaultGovernance));

        // Grant PAUSER_ROLE to techOpsMultisig
        vm.prank(address(defaultGovernance));
        staking.grantRole(PAUSER_ROLE, address(techOpsMultisig));
    }

    // Initialize token balances and approvals
    function _initializeTokenBalances() private {
        address[] memory actors = _getActors();

        for (uint256 i = 0; i < actors.length; i++) {
            _mintTokens(actors[i]);
            _approveAllowances(actors[i]);
        }
    }

    // Mint tokens to an actor
    function _mintTokens(address actor) private {
        vm.prank(actor);
        stakingToken.mint(actor, INITIAL_BALANCE);

        vm.prank(actor);
        maloToken.mint(actor, INITIAL_BALANCE);
    }

    // Approve allowances for an actor
    function _approveAllowances(address actor) private {
        vm.prank(actor);
        stakingToken.approve(address(staking), MAX_UINT);

        vm.prank(actor);
        maloToken.approve(address(staking), MAX_UINT);
    }

    // Modifier to execute a function as an actor
    modifier asActor() {
        vm.prank(_getActor());
        _;
    }
}
