pragma solidity ^0.4.18;

import "../lib/SafeMath.sol";
import "../ownership/Ownable.sol";

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function getTotalSupply() public view returns (uint256);
  function getBalanceOf(address who) public view returns (uint256);
  function getBeneficiaryWeiAmount() public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function approve(address spender, uint256 value) public returns (bool);
}

contract DAICO_ERC20 is Ownable, ERC20 {
    using SafeMath for uint256;

    string public name; //
    string public symbol; //
    uint8 public decimals; // 18
    uint256 public totalSupply; // 5,000,000,000(5 billion)
    address public beneficiary;
	address public owner;
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* EVENTS */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approve(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    /* CONSTRUCTOR */
    function DAICO_ERC20 (
        uint256 initialSupply,
        uint8 decimals_,
        string name_,
        string symbol_
        ) public {
        balanceOf[msg.sender] = 0.2*initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = name_;                                   // Set the name for display purposes
        symbol = symbol_;                               // Set the symbol for display purposes
        decimals = decimals_;                            // Amount of decimals for display purposes
		owner = msg.sender;
    }
    /* OPERATIONS */
    function getTotalSupply() public view returns (uint256 supply) {
        return totalSupply;
    }
    function getBalanceOf(address who) public view returns (uint256 balance) {
        return balanceOf[who];
    }
    function getBeneficiaryWeiAmount() public view returns (uint256 remainingWei){
        return beneficiary.balance; 
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0);
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        Approve(msg.sender, _spender, _value);
        return true;
    }
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));                                // Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0);
        require(balanceOf[_from] >= _value);                 // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }
    function burn(uint256 _value) public returns (bool success) {
		require(_value > 0);
        require(balanceOf[msg.sender] >= _value);            // Check if the sender has enough
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
	function freeze(uint256 _value) public returns (bool success) {
		require(_value > 0);
        require(balanceOf[msg.sender] >= _value);            // Check if the sender has enough
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        Freeze(msg.sender, _value);
        return true;
    }
	function unfreeze(uint256 _value) public returns (bool success) {
        //require(now >= "ico_time+2 month");
		require(_value > 0);
        require(freezeOf[msg.sender] >= _value);            // Check if the sender has enough
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }
}
