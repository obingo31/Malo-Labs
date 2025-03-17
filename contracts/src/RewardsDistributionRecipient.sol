// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract RewardsDistributionRecipient {
    using SafeERC20 for IERC20;

    address public rewardsDistribution;
    IERC20 public maloToken;

    constructor(address _rewardsDistribution, address _maloToken) {
        rewardsDistribution = _rewardsDistribution;
        maloToken = IERC20(_maloToken);
    }

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution");
        _;
    }

    function notifyRewardAmount(uint256 reward) external virtual;

    function setRewardsDistribution(address _rewardsDistribution) external virtual {
        rewardsDistribution = _rewardsDistribution;
    }

    //     function rewardTokensRemaining() public view returns (uint256) {
    //     return maloToken.balanceOf(address(this)) - totalRewardsDistributed;
    // }
}
