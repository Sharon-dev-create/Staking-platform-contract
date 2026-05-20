//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "./StakingToken.sol";
import "./RewardToken.sol";

contract StakingContract {
    StakingToken public stakingToken;
    RewardToken public rewardToken;

    //state variables
    uint256 public constant STAKE_REWARD_RATE = 10; // 10% reward for staking
    address public owner;
    // address public staker;
    address public tokenAddress;
    
    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 reward;
        uint256 totalStaked;
    }

    enum StakingStatus {
        NotStaked,
        Staked,
        Unstaked
    }

    mapping(address => Stake) public stakes;
    mapping(address => StakingStatus) public stakingStatus;

    event Staked(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Invalid address");
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        stakingToken = StakingToken(_tokenAddress);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Add a user to the staker list if they are staking for the first time
        Stake storage user = stakes[msg.sender];

        _updateReward(msg.sender);

        user.amount += amount;
        user.timestamp = block.timestamp;
        user.totalStaked += amount;

        // mark user as staked
        stakingStatus[msg.sender] = StakingStatus.Staked;

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        emit Staked(msg.sender, amount);
    }

    function calculateReward(address staker) public view returns (uint256) {
        Stake memory stakeInfo = stakes[staker];
        if (stakeInfo.amount == 0) {
            return 0;
        }
        uint256 reward = (stakeInfo.amount * STAKE_REWARD_RATE) / 100;
        return reward;
    }

    function _updateReward(address staker) internal {
        Stake storage stakeInfo = stakes[staker];
        uint256 reward = calculateReward(staker);
        stakeInfo.reward += reward;
    }

    function unstake() external {
        require(stakingStatus[msg.sender] == StakingStatus.Staked, "Not staked");
        Stake memory stakeInfo = stakes[msg.sender];
        uint256 reward = calculateReward(msg.sender);
        uint256 totalAmount = stakeInfo.amount + reward;

       
        stakes[msg.sender] = Stake(0, 0, 0, 0);
        stakingStatus[msg.sender] = StakingStatus.Unstaked;
    }

    function claimReward() external {
        require(stakingStatus[msg.sender] == StakingStatus.Staked, "Not staked");
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No reward to claim");

        stakes[msg.sender].timestamp = block.timestamp;
    }    
}