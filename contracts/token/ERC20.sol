pragma solidity ^0.4.23;

import "../lib/SafeMath.sol";
import "../ownership/Ownable.sol";
import "./IERC20.sol";

contract ERC20 is IERC20 {
    /* Library */
    using SafeMath for uint256;
    /* Global Variables */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    address public owner;
    /* Error Messages */
    string constant ERROR_NOT_ENOUGH = "Not Enough Value";

    /* Constructor */
    constructor(
        uint256 initialSupply,
        uint8 decimals_,
        string name_,
        string symbol_
        ) public {
        totalSupply = initialSupply; // Update total supply
        decimals = decimals_;     // Amount of decimals for display purposes
        name = name_;    // Set the name for display purposes
        symbol = symbol_;  // Set the symbol for display purposes
        owner = msg.sender;
        balanceOf[owner] = totalSupply; //set inital owner
    }
    //we can view public variables without view function
    /* Functions */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value, ERROR_NOT_ENOUGH);
        require(balanceOf[_to] + _value > balanceOf[_to], "OverFlow!");
        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);                     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }
    // Allow another contract to spend some tokens in your behalf
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    // A contract attempts to get the coins
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));     // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0);
        require(balanceOf[_from] >= _value, ERROR_NOT_ENOUGH);
        require(balanceOf[_to] + _value > balanceOf[_to], "OverFlow!");
        require(_value <= allowance[_from][msg.sender], "over allowance");
        balanceOf[_from] = balanceOf[_from].safeSub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender].safeSub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value, ERROR_NOT_ENOUGH);
        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);    // Subtract from the sender
        totalSupply = totalSupply.safeSub(_value);     // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
}
