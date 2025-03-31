// // SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

// // Chimera
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {IHevm} from "@chimera/Hevm.sol";

import {Constants} from "src/Constants.sol";
import {ExpectedErrors} from "./ExpectedErrors.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

import {ActorManager} from "../managers/ActorManager.sol";
import {AssetManager} from "../managers/AssetManager.sol";

import {Actor} from "./Actor.sol";
import {Staking} from "src/Staking.sol";

// /**
//  * @title Setup
//  * @notice Chimera test suite for the Staking contract.
//  */
abstract contract Setup is BaseSetup, Constants, ActorManager, AssetManager, ExpectedErrors {
    //     /// @notice Instance of the Hevm cheatcode.
    IHevm internal constant hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /// @notice Protocol contracts.
    ERC20Mock public stakingToken;
    ERC20Mock public rewardToken;

    Staking public staking;

    /// @notice Structure representing a named actor with a deterministic account and its proxy.
    struct NamedActor {
        address account;
        Actor proxy;
    }

    /// @notice Array storing all named actors.
    NamedActor[] public namedActors;

    /**
     * @notice Constructor that triggers the setup process.
     */
    constructor() {
        setup();
    }

    modifier asActor() {
        hevm.prank(_getActor());

        _;
    }

    /**
     * @notice Internal setup function that deploys contracts, configures actors, and initializes balances.
     */
    function setup() internal virtual override {
        _deployContracts();
        _setupNamedActors();
        _initializeTokenBalances();
    }

    /**
     * @notice Deploys the ERC20Mock tokens and the Staking contract.
     */
    function _deployContracts() private {
        stakingToken = new ERC20Mock("Staking Token", "STK");
        rewardToken = new ERC20Mock("Reward Token", "RWD");
        staking = new Staking(address(stakingToken), address(rewardToken), address(this), REWARD_EPOCH, address(this));
    }

    /**
     * @notice Sets up deterministic actors with proxies and configures asset management.
     */
    function _setupNamedActors() private {
        address[] memory tokens = new address[](2);
        tokens[0] = address(stakingToken);
        tokens[1] = address(rewardToken);

        address[] memory contracts = new address[](1);
        contracts[0] = address(staking);

        // Create deterministic actors
        _createNamedActor("shika", tokens);
        _createNamedActor("noko", tokens);
        _createNamedActor("nokonoko", tokens);
        _createNamedActor("koshi", tokens);
        _createNamedActor("tantan", tokens);
        _createNamedActor("mochi", tokens);

        // Configure assets for asset management
        _addAsset(address(stakingToken));
        _addAsset(address(rewardToken));
        _enableAsset(address(stakingToken));
    }

    /**
     * @notice Creates a named actor with a deterministic address derived from its name.
     * @param name The name of the actor.
     * @param tokens The token addresses the actor will manage.
     */
    function _createNamedActor(string memory name, address[] memory tokens) private {
        address account = address(uint160(uint256(keccak256(abi.encode(name)))));
        Actor proxy = new Actor(tokens, address(staking));

        namedActors.push(NamedActor(account, proxy));
        _addActor(address(proxy));
        _enableActor(address(proxy));
    }

    /**
     * @notice Initializes token balances for all actors and the setup contract.
     */
    function _initializeTokenBalances() private {
        address[] memory proxies = _getActors();

        for (uint256 i = 0; i < proxies.length; i++) {
            address proxy = proxies[i];
            stakingToken.mint(proxy, type(uint88).max);
            rewardToken.mint(proxy, type(uint88).max);
            hevm.prank(proxy);
            stakingToken.approve(address(staking), type(uint256).max);
            hevm.prank(proxy);
            rewardToken.approve(address(staking), type(uint256).max);
        }

        stakingToken.mint(address(this), type(uint88).max);
        rewardToken.mint(address(this), type(uint88).max);
    }

    /**
     * @notice Returns an array of actor addresses from ActorManager.
     * @return An array of actor addresses.
     */
    function _getActors() internal view override(ActorManager) returns (address[] memory) {
        return super._getActors();
    }
}
