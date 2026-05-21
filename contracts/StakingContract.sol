//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "./StakingToken.sol";
import "./RewardToken.sol";

contract StakingContract {
    StakingToken public stakingToken;
    RewardToken public rewardToken;

    uint256 public constant STAKE_REWARD_RATE = 10; // 10% annual reward
    uint256 public constant SECONDS_IN_YEAR = 365 days;
    uint256 public constant DEFAULT_MIN_STAKING_PERIOD = 30 days; // default 30 day minimum

    address public owner;
    uint256 public minStakingPeriod; // in seconds

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 stakedAt;
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
    event RewardClaimed(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 stakedAmount, uint256 rewardAmount);
    event MinStakingPeriodUpdated(uint256 periodSeconds);

    constructor(address _stakingTokenAddress, address _rewardTokenAddress) {
        require(_stakingTokenAddress != address(0), "Invalid staking token address");
        require(_rewardTokenAddress != address(0), "Invalid reward token address");

        owner = msg.sender;
        stakingToken = StakingToken(_stakingTokenAddress);
        rewardToken = RewardToken(_rewardTokenAddress);
        minStakingPeriod = DEFAULT_MIN_STAKING_PERIOD; // set default minimum staking period
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setMinStakingPeriod(uint256 _seconds) external onlyOwner {
        minStakingPeriod = _seconds;
        emit MinStakingPeriodUpdated(_seconds);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        Stake storage user = stakes[msg.sender];
        _updateReward(msg.sender);
        // set initial stake timestamp if first time staking
        if (user.amount == 0) {
            user.stakedAt = block.timestamp;
        }

        user.amount += amount;
        user.timestamp = block.timestamp;
        user.totalStaked += amount;
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

        uint256 elapsed = block.timestamp - stakeInfo.timestamp;
        uint256 pendingReward = (stakeInfo.amount * STAKE_REWARD_RATE * elapsed) / SECONDS_IN_YEAR / 100;
        return stakeInfo.reward + pendingReward;
    }

    function _updateReward(address staker) internal {
        Stake storage stakeInfo = stakes[staker];
        if (stakeInfo.amount > 0) {
            uint256 pendingReward = calculateReward(staker) - stakeInfo.reward;
            stakeInfo.reward += pendingReward;
            stakeInfo.timestamp = block.timestamp;
        }
    }

    function unstake() external {
        require(stakingStatus[msg.sender] == StakingStatus.Staked, "Not staked");

        _updateReward(msg.sender);

        Stake memory stakeInfo = stakes[msg.sender];
        
        if (minStakingPeriod > 0) {
            require(block.timestamp >= stakeInfo.stakedAt + minStakingPeriod, "Minimum staking period not reached");
        }

        uint256 amount = stakeInfo.amount;
        uint256 reward = stakeInfo.reward;

        stakes[msg.sender] = Stake(0, 0, 0, 0, 0);
        stakingStatus[msg.sender] = StakingStatus.Unstaked;

        bool stakeTransferSuccess = stakingToken.transfer(msg.sender, amount);
        require(stakeTransferSuccess, "Stake transfer failed");

        if (reward > 0) {
            bool rewardTransferSuccess = rewardToken.transfer(msg.sender, reward);
            require(rewardTransferSuccess, "Reward transfer failed");
        }

        emit Unstaked(msg.sender, amount, reward);
    }

    function claimReward() external {
        require(stakingStatus[msg.sender] == StakingStatus.Staked, "Not staked");

        _updateReward(msg.sender);

        // enforce minimum staking period before allowing reward claims
        if (minStakingPeriod > 0) {
            require(block.timestamp >= stakes[msg.sender].stakedAt + minStakingPeriod, "Minimum staking period not reached");
        }

        uint256 reward = stakes[msg.sender].reward;
        require(reward > 0, "No reward to claim");

        stakes[msg.sender].reward = 0;
        stakes[msg.sender].timestamp = block.timestamp;

        bool rewardTransferSuccess = rewardToken.transfer(msg.sender, reward);
        require(rewardTransferSuccess, "Reward transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }
}
