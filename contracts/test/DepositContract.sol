// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract DepositContract {
    uint256 public constant MAX_DEPOSIT_AMOUNT = 1_000_000e18;
    // Initially set to 30 days, but updatable by the owner.
    uint256 public lockPeriod = 30 days;
    // Penalty rate in percentage for force withdrawals (e.g., 10 means 10%).
    uint256 public constant PENALTY_RATE = 10;

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
        bool withdrawn;
    }

    // Each user can have multiple deposits.
    mapping(address => Deposit[]) public deposits;
    // Total deposited balance for each user.
    mapping(address => uint256) public balances;
    // Total amount deposited in the contract.
    uint256 public totalDeposited;

    address public owner;
    bool public paused;

    // Events
    event Deposited(address indexed user, uint256 amount, uint256 totalDeposited);
    event Withdrawn(address indexed user, uint256 amount);
    event ForceWithdrawn(address indexed user, uint256 amount, uint256 penalty);
    event Paused(address indexed admin);
    event Unpaused(address indexed admin);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Slashed(address indexed user, uint256 amount);
    event LockPeriodUpdated(uint256 newLockPeriod);

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Core deposit functionality
    function deposit() public payable whenNotPaused {
        uint256 amount = msg.value;
        require(totalDeposited + amount <= MAX_DEPOSIT_AMOUNT, "Max deposit exceeded");

        balances[msg.sender] += amount;
        totalDeposited += amount;
        deposits[msg.sender].push(Deposit({amount: amount, timestamp: block.timestamp, withdrawn: false}));

        emit Deposited(msg.sender, amount, totalDeposited);
    }

    // Standard time-locked withdrawal
    function withdraw(
        uint256 depositId
    ) external {
        require(depositId < deposits[msg.sender].length, "Invalid deposit ID");
        Deposit storage userDeposit = deposits[msg.sender][depositId];

        require(!userDeposit.withdrawn, "Already withdrawn");
        require(block.timestamp >= userDeposit.timestamp + lockPeriod, "Funds locked");

        userDeposit.withdrawn = true;
        balances[msg.sender] -= userDeposit.amount;
        totalDeposited -= userDeposit.amount;

        (bool success,) = msg.sender.call{value: userDeposit.amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, userDeposit.amount);
    }

    // Force withdrawal before lock period expires with a penalty fee.
    function forceWithdraw(
        uint256 depositId
    ) external {
        require(depositId < deposits[msg.sender].length, "Invalid deposit ID");
        Deposit storage userDeposit = deposits[msg.sender][depositId];
        require(!userDeposit.withdrawn, "Already withdrawn");

        // Calculate penalty and net amount
        uint256 penalty = (userDeposit.amount * PENALTY_RATE) / 100;
        uint256 amountToSend = userDeposit.amount - penalty;

        userDeposit.withdrawn = true;
        balances[msg.sender] -= userDeposit.amount;
        totalDeposited -= userDeposit.amount;

        // Send penalty fee to owner.
        (bool sentOwner,) = owner.call{value: penalty}("");
        require(sentOwner, "Penalty transfer failed");
        // Send the remaining funds to the user.
        (bool sentUser,) = msg.sender.call{value: amountToSend}("");
        require(sentUser, "User transfer failed");

        emit ForceWithdrawn(msg.sender, amountToSend, penalty);
    }

    // Admin functionality

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function transferOwnership(
        address newOwner
    ) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Emergency slash functionality: owner slashes a user's deposit.
    function slash(address user, uint256 amount) external onlyOwner {
        uint256 remainingSlash = amount;
        uint256 i = 0;

        while (remainingSlash > 0 && i < deposits[user].length) {
            Deposit storage dep = deposits[user][i];
            if (!dep.withdrawn) {
                uint256 available = dep.amount;
                if (available >= remainingSlash) {
                    dep.amount -= remainingSlash;
                    remainingSlash = 0;
                } else {
                    remainingSlash -= available;
                    dep.amount = 0;
                }
            }
            i++;
        }

        require(remainingSlash == 0, "Insufficient slashable deposits");
        totalDeposited -= amount;
        (bool success,) = owner.call{value: amount}("");
        require(success, "Slash transfer failed");
        emit Slashed(user, amount);
    }

    // Admin can update the lock period for testing purposes.
    function updateLockPeriod(
        uint256 newLockPeriod
    ) external onlyOwner {
        lockPeriod = newLockPeriod;
        emit LockPeriodUpdated(newLockPeriod);
    }

    // Additional view functions

    // Returns the number of deposits for a given user.
    function getDepositCount(
        address user
    ) external view returns (uint256) {
        return deposits[user].length;
    }

    // Returns the details of a specific deposit.
    function getDepositDetails(
        address user,
        uint256 depositId
    ) external view returns (uint256 amount, uint256 timestamp, bool withdrawn) {
        require(depositId < deposits[user].length, "Invalid deposit ID");
        Deposit memory d = deposits[user][depositId];
        return (d.amount, d.timestamp, d.withdrawn);
    }

    // Returns the current balance of a user.
    function getUserBalance(
        address user
    ) external view returns (uint256) {
        return balances[user];
    }

    // Fallback and receive functions delegate to deposit()
    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }
}
