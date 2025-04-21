# MALGovernanceStaking Invariants

This document outlines the fundamental truths that must **always hold** for the `MALGovernanceStaking` contract, regardless of user actions or external conditions.

---

## Core Invariants

### 1. **Staking Consistency**
- **What**: The total staked tokens (`totalStaked`) must **always equal** the sum of all individual user balances (`_stakedBalances`).
- **Why**: Prevents inflation/deflation of the total supply. If this breaks, rewards or voting power will be miscalculated.

### 2. **Voting Power Integrity**
- **What**: A user’s voting power (`getVotes()`) must **exactly match** their staked balance if they have tokens deposited. If they withdraw **all tokens**, their voting power must drop to zero.
- **Exception**: Partial withdrawals do **not** reduce voting power in the current implementation (potential bug).

### 3. **Proposal Validity**
- **What**: Proposals can **only execute** if:
  - Voting period has ended.
  - Quorum (`total votes ≥ quorumPercentage × totalStaked`) is met.
  - More voters support (`forVotes`) than oppose (`againstVotes`).
- **Why**: Ensures governance decisions are legitimate and sybil-resistant.

### 4. **Reward Accuracy**
- **What**: Rewards claimed must **never exceed** `(stakedAmount × stakingDuration × rewardRate) / 1e18`.
- **Why**: Prevents users from draining the utility token pool unfairly.

---

### 5. **Access Control**
- **What**: Only addresses with `GOVERNANCE_ADMIN_ROLE` or `POLICY_MANAGER_ROLE` may:
  - Update voting period/quorum.
  - Change withdrawal cooldown.
- **Why**: Unauthorized changes could destabilize governance.

### 6. **Withdrawal Cooldown**
- **What**: Users **cannot withdraw** tokens until `withdrawalCooldown` seconds have passed since their last stake.
- **Why**: Prevents flash-loan attacks or rapid token manipulation.

### 7. **No Double Voting**
- **What**: A user can vote **only once** per proposal, and **only during** the voting period.
- **Why**: Ensures fairness and prevents ballot stuffing.

---

## System Health Invariants

### 8. **No Negative Balances**
- **What**: `totalStaked` and individual staked balances (`_stakedBalances`) must **never be negative**.
- **Why**: Negative balances would corrupt state and reward calculations.

### 9. **Proposal Cleanup**
- **What**: Expired proposals (older than `proposalLifetime`) can be deleted via `cleanExpiredProposals()`.
- **Risk**: Looping through all proposals may cause gas issues (DOS risk).

### 10. **Solvency Check**
- **What**: The contract’s utility token balance must **always cover** pending rewards for all users.
- **Why**: Avoids failed reward claims due to insufficient funds.

---


### A. Partial Withdrawal Delegation
- **Issue**: Users who partially withdraw tokens retain full voting power from their original stake.
- **Example**:  
  Alice stakes 100 tokens → gets 100 votes.  
  Withdraws 50 → still has 100 votes.  
  **Invariant Violated**: Voting power ≠ remaining stake.

### B. Reward Rate Precision
- **Issue**: `rewardRate = 1e18` allows 1 token/sec per staked token. If the utility token has <18 decimals, rewards will round to zero.  
  **Invariant Violated**: Rewards become unusable.

### C. Quorum Precision Loss
- **Issue**: Quorum is calculated as `totalVotes × 100 ≥ totalStaked × quorumPercentage`.  
  Integer division may allow proposals to pass with **insufficient quorum** (e.g., 29.9% rounded to 30%).  
  **Invariant Violated**: Proposals execute without true majority.

---

## How to Test These Invariants

1. **Staking Consistency**:  
   Fuzz-test with random users/stake amounts → assert `totalStaked == sum(balances)`.

2. **Voting Power Check**:  
   After every stake/withdraw, verify `getVotes(user) == stakedBalance`.

3. **Proposal Execution**:  
   Create proposals that fail quorum/expire → ensure they cannot execute.

4. **Reward Drain Test**:  
   Simulate multi-year staking → ensure rewards don’t overflow or drain reserves.

---

**Summary**: These invariants define the "laws" of the system. Any deviation indicates a critical bug. 