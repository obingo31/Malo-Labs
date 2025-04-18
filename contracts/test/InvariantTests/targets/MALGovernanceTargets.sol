// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract MALGovernanceStaking is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // Roles
    bytes32 public constant GOVERNANCE_ADMIN_ROLE = keccak256("GOVERNANCE_ADMIN_ROLE");
    bytes32 public constant POLICY_MANAGER_ROLE = keccak256("POLICY_MANAGER_ROLE");

    // Token contracts
    IVotes public immutable malGovernanceToken;
    IERC20 public immutable malUtilityToken;

    // Governance parameters
    uint256 public votingPeriod = 7 days;
    uint256 public proposalThreshold = 10_000 ether;
    uint256 public quorumPercentage = 30; // 30%
    uint256 public withdrawalCooldown = 2 days;
    uint256 public proposalLifetime = 30 days;

    // Rewards parameters
    uint256 public rewardRate = 1e18; // 1 token per second per staked token

    // Staking state
    uint256 private _totalStaked;
    mapping(address => uint256) private _stakedBalances;
    // lastStakeTime is used to calculate pending rewards
    mapping(address => uint256) public lastStakeTime;
    // accruedRewards stores rewards accumulated but not claimed
    mapping(address => uint256) public accruedRewards;
    // For voters: prevent withdrawal until all proposals they've voted on are finished
    mapping(address => uint256) public lastVotedProposalEnd;

    // Proposal spam prevention: require a cooldown between proposals per user
    mapping(address => uint256) public lastProposalTime;
    uint256 public constant proposalCooldown = 1 days;

    // Proposals system
    struct Proposal {
        address target;
        bytes data;
        address proposer;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    // Tracks if a user has voted on a given proposal
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    uint256 public proposalCount;

    // Events
    event Staked(address indexed citizen, uint256 amount);
    event Withdrawn(address indexed citizen, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address proposer);
    event Voted(uint256 indexed proposalId, address voter, bool support, uint256 power);
    event ProposalExecuted(uint256 indexed proposalId);
    event GovernanceUpdated(string parameter, uint256 newValue);
    event RewardsClaimed(address indexed user, uint256 amount);

    // Errors
    error InsufficientBalance();
    error VotingClosed();
    error AlreadyVoted();
    error NoVotingPower();
    error ProposalAlreadyExecuted();
    error ExecutionFailed();
    error CooldownActive();
    error InvalidPercentage();
    error ProposalCooldownActive();
    error ActiveVotesPreventWithdrawal();

    constructor(address _governanceToken, address _utilityToken, address _daoMultisig) {
        malGovernanceToken = IVotes(_governanceToken);
        malUtilityToken = IERC20(_utilityToken);

        _grantRole(DEFAULT_ADMIN_ROLE, _daoMultisig);
        _grantRole(GOVERNANCE_ADMIN_ROLE, _daoMultisig);
        _grantRole(POLICY_MANAGER_ROLE, _daoMultisig);
    }

    // ────────────────────────────── Core Staking Functions ──────────────────────────────

    function stake(
        uint256 amount
    ) external nonReentrant whenNotPaused {
        if (amount == 0) revert InsufficientBalance();

        // Update rewards before changing staked balance
        _updateRewards(msg.sender);

        _totalStaked += amount;
        _stakedBalances[msg.sender] += amount;
        lastStakeTime[msg.sender] = block.timestamp;

        // Transfer tokens from the user to the contract by casting to IERC20
        IERC20(address(malGovernanceToken)).safeTransferFrom(msg.sender, address(this), amount);

        // Delegate voting power when staking
        _updateDelegation(msg.sender, true);

        emit Staked(msg.sender, amount);
    }

    function withdraw(
        uint256 amount
    ) external nonReentrant {
        if (amount > _stakedBalances[msg.sender]) revert InsufficientBalance();
        if (block.timestamp < lastStakeTime[msg.sender] + withdrawalCooldown) revert CooldownActive();
        if (block.timestamp < lastVotedProposalEnd[msg.sender]) revert ActiveVotesPreventWithdrawal();

        // Update rewards before withdrawal
        _updateRewards(msg.sender);

        // If fully withdrawing, remove delegation
        if (amount == _stakedBalances[msg.sender]) {
            _updateDelegation(msg.sender, false);
        }

        _totalStaked -= amount;
        _stakedBalances[msg.sender] -= amount;

        // Transfer tokens back to the user by casting to IERC20
        IERC20(address(malGovernanceToken)).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    // ────────────────────────────── Rewards Functions ──────────────────────────────

    // Update accrued rewards for a user
    function _updateRewards(
        address user
    ) internal {
        uint256 staked = _stakedBalances[user];
        if (staked == 0) {
            lastStakeTime[user] = block.timestamp;
            return;
        }
        uint256 duration = block.timestamp - lastStakeTime[user];
        uint256 pending = (staked * duration * rewardRate) / 1e18;
        accruedRewards[user] += pending;
        lastStakeTime[user] = block.timestamp;
    }

    // Calculate current pending rewards (without updating state)
    function calculateRewards(
        address user
    ) public view returns (uint256) {
        uint256 staked = _stakedBalances[user];
        if (staked == 0) return accruedRewards[user];
        uint256 duration = block.timestamp - lastStakeTime[user];
        uint256 pending = (staked * duration * rewardRate) / 1e18;
        return accruedRewards[user] + pending;
    }

    function claimRewards() external nonReentrant {
        _updateRewards(msg.sender);
        uint256 rewardsToClaim = accruedRewards[msg.sender];
        if (rewardsToClaim == 0) revert InsufficientBalance();

        accruedRewards[msg.sender] = 0;
        malUtilityToken.safeTransfer(msg.sender, rewardsToClaim);
        emit RewardsClaimed(msg.sender, rewardsToClaim);
    }

    // ────────────────────────────── Governance & Proposals ──────────────────────────────

    function createProposal(address target, bytes calldata data) external returns (uint256) {
        // Check the proposer has enough voting power
        if (malGovernanceToken.getVotes(msg.sender) < proposalThreshold) revert NoVotingPower();
        // Prevent spamming proposals by enforcing a cooldown period per proposer
        if (block.timestamp < lastProposalTime[msg.sender] + proposalCooldown) revert ProposalCooldownActive();
        lastProposalTime[msg.sender] = block.timestamp;

        uint256 proposalId = ++proposalCount;
        proposals[proposalId] = Proposal({
            target: target,
            data: data,
            proposer: msg.sender,
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender);
        return proposalId;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        if (block.timestamp > proposal.endTime) revert VotingClosed();
        if (hasVoted[msg.sender][proposalId]) revert AlreadyVoted();

        uint256 power = malGovernanceToken.getVotes(msg.sender);
        if (power == 0) revert NoVotingPower();

        if (support) {
            proposal.forVotes += power;
        } else {
            proposal.againstVotes += power;
        }
        hasVoted[msg.sender][proposalId] = true;

        // Record the end time of the proposal so voters remain locked until it is finished
        if (proposal.endTime > lastVotedProposalEnd[msg.sender]) {
            lastVotedProposalEnd[msg.sender] = proposal.endTime;
        }

        emit Voted(proposalId, msg.sender, support, power);
    }

    function executeProposal(
        uint256 proposalId
    ) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp <= proposal.endTime) revert VotingClosed();

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        // Check quorum: total votes as a percentage of total staked must meet or exceed quorumPercentage
        if (totalVotes * 100 >= _totalStaked * quorumPercentage && proposal.forVotes > proposal.againstVotes) {
            (bool success,) = proposal.target.call(proposal.data);
            if (!success) revert ExecutionFailed();
            proposal.executed = true;
            emit ProposalExecuted(proposalId);
        }
    }

    // Removes proposals that have expired (beyond the proposalLifetime)
    function cleanExpiredProposals() external {
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].endTime + proposalLifetime < block.timestamp) {
                delete proposals[i];
            }
        }
    }

    // ────────────────────────────── Administration ──────────────────────────────

    function updateVotingPeriod(
        uint256 newPeriod
    ) external onlyRole(POLICY_MANAGER_ROLE) {
        votingPeriod = newPeriod;
        emit GovernanceUpdated("votingPeriod", newPeriod);
    }

    function updateQuorum(
        uint256 newPercentage
    ) external onlyRole(GOVERNANCE_ADMIN_ROLE) {
        if (newPercentage > 100) revert InvalidPercentage();
        quorumPercentage = newPercentage;
        emit GovernanceUpdated("quorumPercentage", newPercentage);
    }

    function setWithdrawalCooldown(
        uint256 newCooldown
    ) external onlyRole(GOVERNANCE_ADMIN_ROLE) {
        withdrawalCooldown = newCooldown;
        emit GovernanceUpdated("withdrawalCooldown", newCooldown);
    }

    // ────────────────────────────── Internal Functions ──────────────────────────────

    // Updates delegation based on staking status
    function _updateDelegation(address user, bool isStaking) internal {
        if (isStaking) {
            malGovernanceToken.delegate(user);
        } else {
            malGovernanceToken.delegate(address(0));
        }
    }

    // ────────────────────────────── View Functions ──────────────────────────────

    function getVotingPower(
        address citizen
    ) external view returns (uint256) {
        return malGovernanceToken.getVotes(citizen);
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function stakedBalance(
        address user
    ) external view returns (uint256) {
        return _stakedBalances[user];
    }

    // Returns an array of active proposal IDs (not yet executed and still within voting period)
    function activeProposals() external view returns (uint256[] memory) {
        uint256 count;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (!proposals[i].executed && block.timestamp <= proposals[i].endTime) {
                count++;
            }
        }

        uint256[] memory active = new uint256[](count);
        uint256 index;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (!proposals[i].executed && block.timestamp <= proposals[i].endTime) {
                active[index++] = i;
            }
        }
        return active;
    }
}
