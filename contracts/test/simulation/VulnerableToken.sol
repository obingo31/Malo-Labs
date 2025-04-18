// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract VulnerableToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _name = "Vulnerable Token";
        _symbol = "VULN";

        // Mint initial tokens to the deployer
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view returns (uint256) {
        return _balances[account];
    }

    // VULNERABILITY: This transfer function calls the receiver contract,
    // which allows for a reentrancy attack
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        // The vulnerability: Make a call to the recipient if it's a contract
        // This enables a malicious contract to reenter the transfer function
        if (recipient.code.length > 0) {
            (bool success,) = recipient.call("");
            require(success, "Callback failed");
        }

        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);

        // Same vulnerability in transferFrom
        if (recipient.code.length > 0) {
            (bool success,) = recipient.call("");
            require(success, "Callback failed");
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}
