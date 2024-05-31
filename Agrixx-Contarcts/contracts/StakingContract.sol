// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract StakingContract is VRFConsumerBase {
    using SafeMath for uint256;

    AGIXXToken public agixxToken;
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public rewards;
    uint256 public totalStaked;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    constructor(address _agixxToken, address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        agixxToken = AGIXXToken(_agixxToken);
        keyHash = _keyHash;
        fee = _fee;
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
        uint256 performanceFactor = getPerformanceFactor();
        rewards[user] = rewards[user].add(stakes[user].mul(performanceFactor).div(100)); // 1% of stake as reward
    }

    function getPerformanceFactor() internal view returns (uint256) {
        // Here we use the randomResult as the performance factor for simplicity.
        // In a real-world scenario, this could be more complex.
        return randomResult % 10 + 1; // Just as an example, returning a value between 1 and 10
    }

    function requestRandomnessForReward() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    // function to withdraw LINK tokens from the contract
    function withdrawLink() external onlyOwner {
        uint256 balance = LINK.balanceOf(address(this));
        require(balance > 0, "No LINK to withdraw");
        LINK.transfer(msg.sender, balance);
    }
}
