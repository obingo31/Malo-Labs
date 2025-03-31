# Staking Contract Invariants & Architecture

This document outlines the core invariants and design principles enforced in the Staking contract.

## Key Invariants

                
|---------------------------|--------------------------------------------------------------------|---------------------------|
| **Total Staked Supply**     | `_totalSupply` matches sum of all `_balances`                      | Direct balance updates in `_stakeFor`/`_unstake`        |
| **Locked Tokens**           | Locked balance ≤ staked balance (`unlocked = balance - locked`)    | `unlockedBalanceOf`             checks                                                                                             |
| **Reward Per Token**        | Accurately tracks rewards based on time/rate                       | `rewardPerToken()` with effective supply handling                                                                                    |
| **Earned Rewards**          | Rewards calculated from stake duration/rate                        | `updateReward` modifier                                                                                           |
| **Protocol Fee**            | Fee (≤10%) deducted from rewards to `feeRecipient`                 | `claimRewards` fee calculation                                                                                        |
| **Lock Allowance**          | Locked amount ≤ manager allowance                                  | `lock()` validation checks                                                                                             |
| **Role-Based Access**       | Critical functions restricted to authorized roles                  | `AccessControl`  Access                                                                                             |
| **Non-Negative Balances**   | No negative balances for stakes/locks/rewards                      | Safe math + revert checks                                                                                             |
| **Correct Token Transfers** | Proper token movements for staking/unstaking                       | `SafeERC20`           operations                                                                                         |
| **Total Locked Tracking**   | `totalLocked` matches sum of individual locks                      | Atomic lock operations                                                                                         |


### 1. Total Staked Supply

```solidity
// _stakeFor
_totalSupply += amount;
_balances[to] += amount;

// _unstake
_totalSupply -= amount;
_balances[user] -= amount;
