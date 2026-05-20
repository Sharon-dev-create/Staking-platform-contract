// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract RewardToken {
	string public name = "RewardToken";
	string public symbol = "RT";
	uint8 public constant decimals = 18;
    
	uint256 public totalSupply;
	address public owner;

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	modifier onlyOwner() {
		require(msg.sender == owner, "RewardToken: caller is not the owner");
		_;
	}

	constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
		name = _name;
		symbol = _symbol;
		owner = msg.sender;
		if (_initialSupply > 0) {
			_mint(msg.sender, _initialSupply);
		}
	}

	function _mint(address to, uint256 amount) internal {
		require(to != address(0), "RewardToken: mint to the zero address");
		totalSupply += amount;
		balanceOf[to] += amount;
		emit Transfer(address(0), to, amount);
	}

	function mint(address to, uint256 amount) external onlyOwner {
		_mint(to, amount);
	}

	function _transfer(address from, address to, uint256 amount) internal {
		require(to != address(0), "RewardToken: transfer to the zero address");
		require(balanceOf[from] >= amount, "RewardToken: transfer amount exceeds balance");
		balanceOf[from] -= amount;
		balanceOf[to] += amount;
		emit Transfer(from, to, amount);
	}

	function transfer(address to, uint256 amount) external returns (bool) {
		_transfer(msg.sender, to, amount);
		return true;
	}

	function approve(address spender, uint256 amount) external returns (bool) {
		allowance[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transferFrom(address from, address to, uint256 amount) external returns (bool) {
		uint256 allowed = allowance[from][msg.sender];
		require(allowed >= amount, "RewardToken: transfer amount exceeds allowance");
		allowance[from][msg.sender] = allowed - amount;
		_transfer(from, to, amount);
		return true;
	}
}

