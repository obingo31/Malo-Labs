🧱 Core Staking Invariants

### The total staked amount (_totalStaked) must always equal the sum of all users' staked balances.


###  No user's staked balance can ever go below zero.


### A user cannot withdraw more than they have staked.

🎁 Reward Distribution Invariants

### Rewards can only be claimed from tokens that have been properly added as reward tokens.


### For each reward token, rewardPerTokenStored must never decrease over time.


### A user cannot claim a reward for a token unless they have earned a non-zero amount of it.


### The earned amount must correctly reflect only the rewards accrued since the last update, avoiding duplicate reward claims.


### The reward token balance in the contract must always be greater than or equal to the sum of all users’ pending rewards.

🔒 Security Invariants
Reentrancy Protection:
All external-facing functions that modify state or transfer tokens must be protected from reentrancy.


### Only addresses with the REWARDS_ADMIN_ROLE can add or remove reward tokens.


### Only an address with the PAUSE_GUARDIAN_ROLE can pause contract functionality.


### When the contract is paused, staking and withdrawing are disallowed.

🛑 Reward Lifecycle Invariants

### New rewards for a token can only be added after the previous reward period has ended.

## Cannot Remove Active Rewards:
### A reward token cannot be removed while its distribution period is still active.

