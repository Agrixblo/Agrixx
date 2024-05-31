// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingContract {
    using SafeMath for uint256;

    AGIXXToken public agixxToken;
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public rewards;
    uint256 public totalStaked;

    constructor(address _agixxToken) {
        agixxToken = AGIXXToken(_agixxToken);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        agixxToken.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] = stakes[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0 && amount <= stakes[msg.sender], "Invalid unstake amount");
        updateReward(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        agixxToken.transfer(msg.sender, amount);
    }

    function claimReward() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No reward to claim");
        rewards[msg.sender] = 0;
        agixxToken.transfer(msg.sender, reward);
    }

    function updateReward(address user) internal {
        uint256 performanceFactor = 1; // Assume 1 for now
        rewards[user] = rewards[user].add(stakes[user].mul(performanceFactor).div(100)); // 1% of stake as reward
    }
}
