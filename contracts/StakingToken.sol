//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract StakingToken{
    //state variables
    string public name = "StakeToken";
    string public symbol = "STK";
    uint8 public decimals = 18;

    address public owner;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    modifier onlyOwner(){
        require(msg.sender == owner, "Not owner");
        _;
    }

    event Staked(address indexed user, uint256 amount);

    constructor(string memory _name, string memory _symbol,
     uint256 _initialSupply) {  
        owner = msg.sender;
        name = _name;
        symbol = _symbol;

        totalSupply = _initialSupply * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");

        uint256 value = amount * 10 ** decimals;

        totalSupply += value;
        balanceOf[to] += value;
        
    }

    function burn(uint256 amount) public {
       uint256 value = amount * 10 ** decimals;

       require(balanceOf[msg.sender] >= value, "Not enough balance");
       
       balanceOf[msg.sender] -= value;
       totalSupply -= value;
    }

    function approve(address spender, uint256 amount) external returns (bool){
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) public returns(bool){
       require(to != address(0), "Invalid address");
       require(balanceOf[msg.sender] >= amount, "Not enough balance");

       balanceOf[msg.sender] -= amount;
       balanceOf[to] += amount;

       return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= amount, "Not enough balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        return true;
    }

}