// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract MockVotesToken is ERC20, IVotes {
    mapping(address => address) private _delegates;
    mapping(address => uint256) private _voteBalances;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    // --- IVotes Interface Implementation ---

    function getVotes(address account) public view override returns (uint256) {
        return _voteBalances[account];
    }

    function getPastVotes(address, uint256) public pure override returns (uint256) {
        revert("Past votes not implemented");
    }

    function getPastTotalSupply(uint256) public pure override returns (uint256) {
        revert("Past total supply not implemented");
    }

    function delegates(address account) public view override returns (address) {
        return _delegates[account] != address(0) ? _delegates[account] : account;
    }

    function delegate(address delegatee) public override {
        require(delegatee != address(0), "Cannot delegate to zero address");
        address currentDelegate = delegates(msg.sender);
        
        if (currentDelegate != delegatee) {
            uint256 amount = balanceOf(msg.sender);
            _moveVotingPower(currentDelegate, delegatee, amount);
            _delegates[msg.sender] = delegatee;
            emit DelegateChanged(msg.sender, currentDelegate, delegatee);
        }
    }

    function delegateBySig(address, uint256, uint256, uint8, bytes32, bytes32) public pure override {
        revert("Signature delegation not implemented");
    }

    // --- Core Voting Power Logic ---

    function _moveVotingPower(address from, address to, uint256 amount) internal {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                uint256 fromOld = _voteBalances[from];
                _voteBalances[from] = fromOld - amount;
                emit DelegateVotesChanged(from, fromOld, fromOld - amount);
            }
            if (to != address(0)) {
                uint256 toOld = _voteBalances[to];
                _voteBalances[to] = toOld + amount;
                emit DelegateVotesChanged(to, toOld, toOld + amount);
            }
        }
    }

    // --- ERC20 Override with Voting Power Tracking ---

    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);

        // Handle voting power changes
        if (from != address(0)) {
            address fromDelegate = delegates(from);
            _moveVotingPower(fromDelegate, address(0), value);
        }

        if (to != address(0)) {
            address toDelegate = delegates(to);
            _moveVotingPower(address(0), toDelegate, value);
        }
    }
}