// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("StakingModule", (m) => {
  // Deploy StakingToken
  const stakingTokenName = m.getParameter("stakingTokenName", "StakeToken");
  const stakingTokenSymbol = m.getParameter("stakingTokenSymbol", "STK");
  const stakingTokenInitialSupply = m.getParameter("stakingTokenInitialSupply", 1000000n);

  const stakingToken = m.contract("StakingToken", [
    stakingTokenName,
    stakingTokenSymbol,
    stakingTokenInitialSupply,
  ]);

  // Deploy RewardToken
  const rewardTokenName = m.getParameter("rewardTokenName", "RewardToken");
  const rewardTokenSymbol = m.getParameter("rewardTokenSymbol", "RT");
  const rewardTokenInitialSupply = m.getParameter("rewardTokenInitialSupply", 500000n);

  const rewardToken = m.contract("RewardToken", [
    rewardTokenName,
    rewardTokenSymbol,
    rewardTokenInitialSupply,
  ]);

  // Deploy StakingContract with both token addresses
  const stakingContract = m.contract("StakingContract", [
    stakingToken,
    rewardToken,
  ]);

  return { stakingToken, rewardToken, stakingContract };
});
