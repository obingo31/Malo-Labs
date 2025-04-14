// SPDX-License-Identifier: MIT
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
    IERC20 public immutable malGovernanceToken; // For transfers
    IVotes public immutable malGovernanceVotes; // For voting
    IERC20 public immutable malUtilityToken;

    // Governance parameters
    uint256 public votingPeriod = 7 days;
    uint256 public proposalThreshold = 10_000 ether;
    uint256 public quorumPercentage = 30; // 30%
    uint256 public withdrawalCooldown = 2 days;
    uint256 public proposalLifetime = 30 days;

    // Staking and rewards
    uint256 private _totalStaked;
    uint256 public rewardRate = 1e18; // 1 token per second per staked token
    mapping(address => uint256) private _stakedBalances;
    mapping(address => uint256) public lastStakeTime;

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
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    uint256 public proposalCount;

    event Staked(address indexed citizen, uint256 amount);
    event Withdrawn(address indexed citizen, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address proposer);
    event Voted(uint256 indexed proposalId, address voter, bool support, uint256 power);
    event ProposalExecuted(uint256 indexed proposalId);
    event GovernanceUpdated(string parameter, uint256 newValue);
    event RewardsClaimed(address indexed user, uint256 amount);

    error InsufficientBalance();
    error VotingClosed();
    error AlreadyVoted();
    error NoVotingPower();
    error ProposalAlreadyExecuted();
    error ExecutionFailed();
    error CooldownActive();
    error InvalidPercentage();

    constructor(address _governanceToken, address _utilityToken, address _daoMultisig) {
        malGovernanceToken = IERC20(_governanceToken);
        malGovernanceVotes = IVotes(_governanceToken);
        malUtilityToken = IERC20(_utilityToken);

        _grantRole(DEFAULT_ADMIN_ROLE, _daoMultisig);
        _grantRole(GOVERNANCE_ADMIN_ROLE, _daoMultisig);
        _grantRole(POLICY_MANAGER_ROLE, _daoMultisig);
    }

    // Core staking functions
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert InsufficientBalance();

        _updateDelegation(msg.sender, true);
        _totalStaked += amount;
        _stakedBalances[msg.sender] += amount;
        lastStakeTime[msg.sender] = block.timestamp;

        malGovernanceToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        if (amount > _stakedBalances[msg.sender]) revert InsufficientBalance();
        if (block.timestamp < lastStakeTime[msg.sender] + withdrawalCooldown) revert CooldownActive();

        if (amount == _stakedBalances[msg.sender]) {
            _updateDelegation(msg.sender, false);
        }

        _totalStaked -= amount;
        _stakedBalances[msg.sender] -= amount;

        malGovernanceToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    // Governance functions
    function createProposal(address target, bytes calldata data) external returns (uint256) {
        if (malGovernanceVotes.getVotes(msg.sender) < proposalThreshold) revert NoVotingPower();

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

        uint256 power = malGovernanceVotes.getVotes(msg.sender);
        if (power == 0) revert NoVotingPower();

        if (support) {
            proposal.forVotes += power;
        } else {
            proposal.againstVotes += power;
        }

        hasVoted[msg.sender][proposalId] = true;
        emit Voted(proposalId, msg.sender, support, power);
    }

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp <= proposal.endTime) revert VotingClosed();

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        if (totalVotes * 100 >= _totalStaked * quorumPercentage && proposal.forVotes > proposal.againstVotes) {
            (bool success,) = proposal.target.call(proposal.data);
            if (!success) revert ExecutionFailed();
            proposal.executed = true;
            emit ProposalExecuted(proposalId);
        }
    }

    // Rewards system
    function calculateRewards(address user) public view returns (uint256) {
        uint256 stakedDuration = block.timestamp - lastStakeTime[user];
        return (_stakedBalances[user] * stakedDuration * rewardRate) / 1e18;
    }

    function claimRewards() external nonReentrant {
        uint256 rewards = calculateRewards(msg.sender);
        if (rewards == 0) revert InsufficientBalance();

        lastStakeTime[msg.sender] = block.timestamp;
        malUtilityToken.safeTransfer(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    // Administration functions
    function updateVotingPeriod(uint256 newPeriod) external onlyRole(POLICY_MANAGER_ROLE) {
        votingPeriod = newPeriod;
        emit GovernanceUpdated("votingPeriod", newPeriod);
    }

    function updateQuorum(uint256 newPercentage) external onlyRole(GOVERNANCE_ADMIN_ROLE) {
        if (newPercentage > 100) revert InvalidPercentage();
        quorumPercentage = newPercentage;
        emit GovernanceUpdated("quorumPercentage", newPercentage);
    }

    function setWithdrawalCooldown(uint256 newCooldown) external onlyRole(GOVERNANCE_ADMIN_ROLE) {
        withdrawalCooldown = newCooldown;
        emit GovernanceUpdated("withdrawalCooldown", newCooldown);
    }

    function cleanExpiredProposals() external {
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].endTime + proposalLifetime < block.timestamp) {
                delete proposals[i];
            }
        }
    }

    // Internal functions
    function _updateDelegation(address user, bool isStaking) internal {
        if (isStaking) {
            malGovernanceVotes.delegate(user);
        } else {
            malGovernanceVotes.delegate(address(0));
        }
    }

    // View functions
    function getVotingPower(address citizen) external view returns (uint256) {
        return malGovernanceVotes.getVotes(citizen);
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function stakedBalance(address user) external view returns (uint256) {
        return _stakedBalances[user];
    }

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
