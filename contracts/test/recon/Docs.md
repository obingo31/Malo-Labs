1. Research & Critical Exposure
Properties that must always hold:

totalStaked == sum(stakedBalances) (No supply inflation)

Voting power = staked balance (when delegated)

Proposals execute only if quorum met and majority support

Reward calculations are time-dependent and non-negative

Most Critical Exposure:

Reward Drain: Incorrect rewardRate logic draining utility tokens

Quorum Bypass: Proposals executing without sufficient votes

Reentrancy: During withdraw() or claimRewards()

Cooldown Bypass: Early withdrawals draining staked tokens

2. Invariants & State Transitions
Category	Contract-Specific Implementation
Preconditions	- stake(): User balance ≥ amount, contract approved
- createProposal(): Voting power ≥ threshold
Postconditions	- After stake(): totalStaked += amount
- After withdraw(): Voting power reduced
State Transitions	State Transition Diagram
3. Valid/Invalid States
Valid States:

After successful stake
```solidity
assert(stakedBalances[user] > 0);
assert(malGovernanceVotes.getVotes(user) == stakedBalances[user]);
```

After proposal execution
```scss
assert(proposals[id].executed == true);
Invalid States (Test for Reverts):
```

```solidity
// Attempt to create proposal without threshold
vm.expectRevert(NoVotingPower.selector);
staking.createProposal(target, data);
```

```js
// Attempt to withdraw during cooldown
vm.expectRevert(CooldownActive.selector);
staking.withdraw(amount);
```

4. High-Level Properties
```ruby
Property	            Test Case Example
Validity	  activeProposals() returns only unexpired/une executed proposals
Value States  calculateRewards() matches (staked * duration * rate)/1e18
Solvency	  malUtilityToken.balanceOf(staking) >= sum(pending rewards)
Transitions	  proposalCount increases by 1 after createProposal()
```

5. Balance Checks
Before/After Stake:

```solidity
uint256 preBal = malGovernanceToken.balanceOf(user);
staking.stake(100);
uint256 postBal = malGovernanceToken.balanceOf(user);

assertEq(preBal - postBal, 100); // User balance
assertEq(staking.totalStaked(), prevTotal + 100); // Contract balance
```
Before/After Proposal Execution:

```s
uint256 preEthBal = address(target).balance;
staking.executeProposal(proposalId);
uint256 postEthBal = address(target).balance;

assertEq(postEthBal - preEthBal, expectedValue); // For ETH transfers
```
TROPHIES:

6. Bug Hunting Checklist
Reward Calculation Overflow:
```bash
(staked * duration * rate) could exceed uint256 if rate > 1e18/staked.
```
Fix: Use scaling factors or bounds-check rewardRate.

Proposal Lifetime DOS:
```S
cleanExpiredProposals() loops over all proposals - gas griefing.
```
Fix: Limit iteration range or use expiration timestamps.

Delegation Mismatch:
Partial withdrawals don’t reduce delegation proportionally.
Fix: Explicitly update delegation on partial withdrawals.

Quorum Precision Loss:
```s
totalVotes * 100 vs _totalStaked * percentage - integer division errors.
```
Fix: Use scaled percentages (e.g., quorum = 30 * 1e18).

