// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {PropertiesAsserts} from "properties/util/PropertiesHelper.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {TestERC20Token} from "properties/ERC4626/util/TestERC20Token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Staker} from "../../src/Staker.sol";
import {IHevm} from "properties/util/Hevm.sol";

/*
SOLC_VERSION=0.8.20 echidna ./test/EchidnaTesting/E2E.sol \
  --contract E2E \
  --config ./test/EchidnaTesting/echidna.yaml \
  --workers 10
 */

contract StakerActor {
    Staker public immutable staker;
    IERC20 public immutable stakingToken;

    constructor(
        Staker _staker
    ) {
        staker = _staker;
        stakingToken = IERC20(staker.stakingToken());
        stakingToken.approve(address(staker), type(uint256).max);
    }

    function stake(
        uint256 amount
    ) external {
        staker.stake(amount);
    }

    function withdraw(
        uint256 amount
    ) external {
        staker.withdraw(amount);
    }

    function claimRewards(
        address rewardToken
    ) external {
        staker.claimRewards(rewardToken);
    }

    function claimAllRewards() external {
        staker.claimAllRewards();
    }
}

contract E2E is PropertiesAsserts {
    using Strings for uint256;

    IHevm constant hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    Staker public staker;
    TestERC20Token public stakingToken;
    TestERC20Token public rewardToken1;
    TestERC20Token public rewardToken2;

    address constant ADMIN = address(0x1001);
    address constant PAUSE_GUARDIAN = address(0x1002);
    uint256 constant INITIAL_BALANCE = 1000 ether;

    StakerActor[] public actors;
    uint256 public constant START_TIMESTAMP = 1_706_745_600;
    uint256 public constant START_BLOCK = 17_336_000;

    constructor() {
        hevm.warp(START_TIMESTAMP);
        hevm.roll(START_BLOCK);

        // Deploy tokens
        stakingToken = new TestERC20Token("Staking Token", "STK", 18);
        rewardToken1 = new TestERC20Token("Reward Token 1", "RWD1", 18);
        rewardToken2 = new TestERC20Token("Reward Token 2", "RWD2", 18);

        // Deploy staker
        staker = new Staker(address(stakingToken), ADMIN, PAUSE_GUARDIAN);

        // Create actors
        for (uint256 i = 0; i < 3; i++) {
            actors.push(new StakerActor(staker));
        }

        // Fund actors
        for (uint256 i = 0; i < actors.length; i++) {
            address actor = address(actors[i]);
            stakingToken.mint(actor, INITIAL_BALANCE);
            rewardToken1.mint(actor, INITIAL_BALANCE);
            rewardToken2.mint(actor, INITIAL_BALANCE);
        }

        // Setup rewards
        rewardToken1.mint(ADMIN, 100_000 ether);
        rewardToken2.mint(ADMIN, 100_000 ether);

        hevm.prank(ADMIN);
        rewardToken1.approve(address(staker), type(uint256).max);

        hevm.prank(ADMIN);
        rewardToken2.approve(address(staker), type(uint256).max);

        hevm.prank(ADMIN);
        staker.addReward(address(rewardToken1), 1000 ether, 365 days);

        hevm.prank(ADMIN);
        staker.addReward(address(rewardToken2), 1000 ether, 365 days);
    }

    /* ================================================================
                            Echidna invariants
       ================================================================ */
    function echidna_total_staked_matches_sum() public view returns (bool) {
        uint256 sum;
        for (uint256 i = 0; i < actors.length; i++) {
            sum += staker.stakedBalanceOf(address(actors[i]));
        }
        return staker.totalStaked() == sum;
    }

    function echidna_staking_token_balance_consistent() public view returns (bool) {
        return stakingToken.balanceOf(address(staker)) == staker.totalStaked();
    }

    function echidna_reward_rate_nonzero_during_active_period() public view returns (bool) {
        (uint256 duration1,,,) = staker.rewards(address(rewardToken1));
        (uint256 duration2,,,) = staker.rewards(address(rewardToken2));

        return duration1 > 0 && duration2 > 0;
    }

    function echidna_no_negative_balances() public view returns (bool) {
        for (uint256 i = 0; i < actors.length; i++) {
            if (staker.stakedBalanceOf(address(actors[i])) > INITIAL_BALANCE) {
                return false;
            }
        }
        return true;
    }

    function echidna_stakingIsConsistent() public view returns (bool success) {
        // Check that the sum of all user staked balances matches totalStaked
        uint256 sum;
        for (uint256 i = 0; i < actors.length; i++) {
            address actor = address(actors[i]);
            sum += staker.stakedBalanceOf(actor);
        }
        if (sum != staker.totalStaked()) return false;

        // Optionally, check that reward tokens are registered and earned is non-negative
        for (uint256 i = 0; i < actors.length; i++) {
            address actor = address(actors[i]);
            for (uint256 j = 0; j < 2; j++) {
                address rewardToken = j == 0 ? address(rewardToken1) : address(rewardToken2);
                if (!staker.isRewardToken(rewardToken)) return false;
                // earned should never underflow
                if (staker.earned(actor, rewardToken) < 0) return false;
            }
        }

        return true;
    }

    /* ================================================================
                            Functions used for system interaction
       ================================================================ */
    function stake(uint8 actorIndex, uint256 amount) public {
        emit LogUint256("[stake] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));
        amount = clampBetween(amount, 1, stakingToken.balanceOf(address(actors[actorIndex])));

        uint256 preStaked = staker.stakedBalanceOf(address(actors[actorIndex]));
        uint256 preTotal = staker.totalStaked();

        actors[actorIndex].stake(amount);

        emit LogString(string.concat("Staked ", amount.toString(), " tokens by actor ", uint256(actorIndex).toString()));

        assertEq(staker.stakedBalanceOf(address(actors[actorIndex])), preStaked + amount, "Staked balance mismatch");
        assertEq(staker.totalStaked(), preTotal + amount, "Total staked mismatch");
    }

    function withdraw(uint8 actorIndex, uint256 amount) public {
        emit LogUint256("[withdraw] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));
        uint256 userStaked = staker.stakedBalanceOf(address(actors[actorIndex]));
        amount = clampBetween(amount, 1, userStaked);

        uint256 preStaked = userStaked;
        uint256 preTotal = staker.totalStaked();
        uint256 preBalance = stakingToken.balanceOf(address(actors[actorIndex]));

        actors[actorIndex].withdraw(amount);

        emit LogString(
            string.concat("Withdrew ", amount.toString(), " tokens by actor ", uint256(actorIndex).toString())
        );

        assertEq(staker.stakedBalanceOf(address(actors[actorIndex])), preStaked - amount, "Staked balance mismatch");
        assertEq(staker.totalStaked(), preTotal - amount, "Total staked mismatch");
        assertEq(stakingToken.balanceOf(address(actors[actorIndex])), preBalance + amount, "Token balance mismatch");
    }

    function claimRewards(uint8 actorIndex, uint8 tokenIndex) public {
        emit LogUint256("[claimRewards] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));
        tokenIndex = uint8(clampBetween(tokenIndex, 0, 1));
        address rewardToken = tokenIndex == 0 ? address(rewardToken1) : address(rewardToken2);

        uint256 earned = staker.earned(address(actors[actorIndex]), rewardToken);
        if (earned == 0) return;

        uint256 preBalance = IERC20(rewardToken).balanceOf(address(actors[actorIndex]));
        actors[actorIndex].claimRewards(rewardToken);

        emit LogString(
            string.concat("Claimed ", earned.toString(), " rewards by actor ", uint256(actorIndex).toString())
        );

        assertEq(
            IERC20(rewardToken).balanceOf(address(actors[actorIndex])), preBalance + earned, "Reward claim mismatch"
        );
        assertEq(staker.earned(address(actors[actorIndex]), rewardToken), 0, "Rewards not reset");
    }

    function claimAllRewards(
        uint8 actorIndex
    ) public {
        emit LogUint256("[claimAllRewards] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));

        uint256 earned1 = staker.earned(address(actors[actorIndex]), address(rewardToken1));
        uint256 earned2 = staker.earned(address(actors[actorIndex]), address(rewardToken2));
        uint256 preBalance1 = rewardToken1.balanceOf(address(actors[actorIndex]));
        uint256 preBalance2 = rewardToken2.balanceOf(address(actors[actorIndex]));

        actors[actorIndex].claimAllRewards();

        emit LogString(string.concat("Claimed all rewards by actor ", uint256(actorIndex).toString()));

        if (earned1 > 0) {
            assertEq(
                rewardToken1.balanceOf(address(actors[actorIndex])), preBalance1 + earned1, "Token1 claim mismatch"
            );
        }
        if (earned2 > 0) {
            assertEq(
                rewardToken2.balanceOf(address(actors[actorIndex])), preBalance2 + earned2, "Token2 claim mismatch"
            );
        }
    }

    function addReward(uint8 tokenIndex, uint256 totalRewards, uint256 duration) public {
        emit LogUint256("[addReward] block.timestamp:", block.timestamp);

        tokenIndex = uint8(clampBetween(tokenIndex, 0, 1));
        address rewardToken = tokenIndex == 0 ? address(rewardToken1) : address(rewardToken2);
        totalRewards = clampBetween(totalRewards, 1, 1000 ether);
        duration = clampBetween(duration, 1 days, 365 days);

        hevm.prank(ADMIN);
        staker.addReward(rewardToken, totalRewards, duration);

        emit LogString(
            string.concat(
                "Added reward: token=",
                Strings.toHexString(rewardToken),
                " amount=",
                totalRewards.toString(),
                " duration=",
                duration.toString()
            )
        );

        (uint256 rewardDuration,,,) = staker.rewards(rewardToken);
        assertEq(rewardDuration, duration, "Duration mismatch");
        require(staker.isRewardToken(rewardToken), "Token not registered");
    }

    function warp(
        uint256 timeJump
    ) public {
        timeJump = clampBetween(timeJump, 1 days, 365 days);
        hevm.warp(block.timestamp + timeJump);
        emit LogString(string.concat("Warped ", timeJump.toString(), " seconds"));
    }

    /* ================================================================
                            Properties:
            checking if max* functions are aligned with ERC4626
       ================================================================ */
    function maxStake_correctMax(
        uint8 actorIndex
    ) public {
        emit LogUint256("[maxStake_correctMax] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));
        uint256 maxAmount = stakingToken.balanceOf(address(actors[actorIndex]));
        require(maxAmount > 0, "Max stake is zero");

        uint256 preStaked = staker.stakedBalanceOf(address(actors[actorIndex]));
        uint256 preTotal = staker.totalStaked();

        actors[actorIndex].stake(maxAmount);

        assertEq(staker.stakedBalanceOf(address(actors[actorIndex])), preStaked + maxAmount, "Staked balance mismatch");
        assertEq(staker.totalStaked(), preTotal + maxAmount, "Total staked mismatch");
    }

    function maxWithdraw_correctMax(
        uint8 actorIndex
    ) public {
        emit LogUint256("[maxWithdraw_correctMax] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));
        uint256 maxAmount = staker.stakedBalanceOf(address(actors[actorIndex]));
        require(maxAmount > 0, "Max withdraw is zero");

        uint256 preStaked = maxAmount;
        uint256 preTotal = staker.totalStaked();
        uint256 preBalance = stakingToken.balanceOf(address(actors[actorIndex]));

        actors[actorIndex].withdraw(maxAmount);

        assertEq(staker.stakedBalanceOf(address(actors[actorIndex])), 0, "Staked balance should be zero");
        assertEq(staker.totalStaked(), preTotal - preStaked, "Total staked mismatch");
        assertEq(stakingToken.balanceOf(address(actors[actorIndex])), preBalance + preStaked, "Token balance mismatch");
    }

    function maxStake_correctReturnValue(
        uint8 actorIndex
    ) public {
        emit LogUint256("[maxStake_correctReturnValue] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));
        address actor = address(actors[actorIndex]);
        uint256 maxStake = stakingToken.balanceOf(actor);

        require(maxStake != 0, "Zero tokens to stake");

        emit LogString(string.concat("Max tokens to stake: ", maxStake.toString()));

        // Try to stake the max amount
        try actors[actorIndex].stake(maxStake) {
            // check post-conditions here
        } catch {
            assert(false);
        }
    }

    /* ================================================================
                            Other properties
       ================================================================ */
    function stakeNeverZero(uint8 actorIndex, uint256 amount) public {
        emit LogUint256("[stakeNeverZero] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));
        amount = clampBetween(amount, 1, stakingToken.balanceOf(address(actors[actorIndex])));

        uint256 preStaked = staker.stakedBalanceOf(address(actors[actorIndex]));
        actors[actorIndex].stake(amount);

        uint256 postStaked = staker.stakedBalanceOf(address(actors[actorIndex]));
        assertGt(postStaked, preStaked, "Stake should increase balance");
    }

    function withdrawNeverZero(uint8 actorIndex, uint256 amount) public {
        emit LogUint256("[withdrawNeverZero] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));
        uint256 userStaked = staker.stakedBalanceOf(address(actors[actorIndex]));
        require(userStaked > 0, "No staked balance");

        amount = clampBetween(amount, 1, userStaked);

        uint256 preStaked = userStaked;
        actors[actorIndex].withdraw(amount);

        uint256 postStaked = staker.stakedBalanceOf(address(actors[actorIndex]));
        assertLt(postStaked, preStaked, "Withdraw should decrease balance");
    }

    function reward_claim_consistency(
        uint8 actorIndex
    ) public {
        emit LogUint256("[reward_claim_consistency] block.timestamp:", block.timestamp);

        actorIndex = uint8(clampBetween(actorIndex, 0, actors.length - 1));
        address actorAddr = address(actors[actorIndex]);

        uint256 earned1Before = staker.earned(actorAddr, address(rewardToken1));
        uint256 earned2Before = staker.earned(actorAddr, address(rewardToken2));

        actors[actorIndex].claimAllRewards();

        uint256 earned1After = staker.earned(actorAddr, address(rewardToken1));
        uint256 earned2After = staker.earned(actorAddr, address(rewardToken2));

        assertEq(earned1After, 0, "Rewards not reset for token1");
        assertEq(earned2After, 0, "Rewards not reset for token2");

        if (earned1Before > 0 || earned2Before > 0) {
            emit LogString(
                string.concat("Claimed rewards: ", earned1Before.toString(), " + ", earned2Before.toString())
            );
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        ERC20 PROPERTIES                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Total supply should only change by mint or burn
    function test_ERC20_constantSupply() public view returns (bool) {
        // If token is mintable/burnable, skip this property
        uint256 expectedSupply = 1000 ether * actors.length + 200_000 ether; // initial actor + admin mints
        return stakingToken.totalSupply() == expectedSupply;
    }

    // User balance must not exceed total supply
    function test_ERC20_userBalanceNotExceedSupply() public view returns (bool) {
        for (uint256 i = 0; i < actors.length; i++) {
            if (stakingToken.balanceOf(address(actors[i])) > stakingToken.totalSupply()) {
                return false;
            }
        }
        return true;
    }

    // No negative balances (redundant in Solidity, but for completeness)
    function test_ERC20_noNegativeBalances() public view returns (bool) {
        for (uint256 i = 0; i < actors.length; i++) {
            if (stakingToken.balanceOf(address(actors[i])) < 0) {
                return false;
            }
        }
        return true;
    }

    // Sum of all balances <= total supply
    function echidna_ERC20_sumBalancesNotExceedSupply() public view returns (bool) {
        uint256 sum;
        for (uint256 i = 0; i < actors.length; i++) {
            sum += stakingToken.balanceOf(address(actors[i]));
        }

        sum += stakingToken.balanceOf(address(staker));
        return sum <= stakingToken.totalSupply();
    }

    // Address zero should have zero balance
    function test_ERC20external_zeroAddressBalance() public {
        assertEq(stakingToken.balanceOf(address(0)), 0, "Address zero balance not equal to zero");
    }

    // Transfers to zero address should not be allowed
    function echidna_ERC20external_transferToZeroAddress() public returns (bool) {
        if (stakingToken.totalSupply() == 0) return true;

        uint256 balance = stakingToken.balanceOf(address(this));
        if (balance == 0) return true;

        try stakingToken.transfer(address(0), balance) {
            return false;
        } catch {
            return true;
        }
    }

    // Select an actor by index, clamped to valid range
    function _selectActor(
        uint8 index
    ) internal returns (StakerActor actor) {
        uint256 actorIndex = clampBetween(uint256(index), 0, actors.length - 1);
        return actors[actorIndex];
    }

    // Overflow check for two uint256 values
    function _overflowCheck(uint256 a, uint256 b) internal pure {
        uint256 c;
        unchecked {
            c = a + b;
        }
        require(c >= a, "OVERFLOW!");
    }

    // Get staking token balance of the staker contract
    function _stakingTokenBalanceOfStaker() internal view returns (uint256 assets) {
        assets = stakingToken.balanceOf(address(staker));
    }

    function echidna_ERC20_sumBalancesNoOverflow() public view returns (bool) {
        uint256 sum = 0;
        for (uint256 i = 0; i < actors.length; i++) {
            // overflow check utility before adding
            _overflowCheck(sum, stakingToken.balanceOf(address(actors[i])));
            sum += stakingToken.balanceOf(address(actors[i]));
        }
        // Check overflow for adding staker contract's balance
        _overflowCheck(sum, stakingToken.balanceOf(address(staker)));
        sum += stakingToken.balanceOf(address(staker));

        // The sum should never exceed total supply
        return sum <= stakingToken.totalSupply();
    }
}
