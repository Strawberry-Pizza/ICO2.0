pragma solidity ^0.4.23;

import "../lib/SafeMath.sol";
import "../ownership/Ownable.sol";
import "./IERC20.sol";

contract ERC20 is Ownable, IERC20 {
    /* Library */
    using SafeMath for uint256;
    /* Global Variables */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    address public owner;
    /* Events */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    /* Error Messages */
    string constant ERROR_NOT_ENOUGH = "Not Enough Value";

    /* Constructor */
    constructor(
        uint256 initialSupply,
        uint8 decimals_,
        string name_,
        string symbol_
        ) public {
        totalSupply = initialSupply;                        // Update total supply
        decimals = decimals_;                            // Amount of decimals for display purposes
        name = name_;                                   // Set the name for display purposes
        symbol = symbol_;                               // Set the symbol for display purposes
        owner = msg.sender;
    }
    /* View Functions */
    function getTotalSupply() view public returns(uint256) { return totalSupply; }
    function getBalanceOf(address account) view public returns(uint256) { return balanceOf[account]; }
    /* Functions */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value, ERROR_NOT_ENOUGH);
        require(balanceOf[_to] + _value > balanceOf[_to], "OverFlow!");
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
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
        require(_to != address(0));                                // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0);
        require(balanceOf[_from] >= _value, ERROR_NOT_ENOUGH);
        require(balanceOf[_to] + _value > balanceOf[_to], "OverFlow!");
        require(_value <= allowance[_from][msg.sender], "over allowance");
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value, ERROR_NOT_ENOUGH);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    function freeze(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value, ERROR_NOT_ENOUGH);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    function unfreeze(uint256 _value) public returns (bool success) {
        //require(now >= "ico_time+2 month");
        require(_value > 0);
        require(freezeOf[msg.sender] >= _value, ERROR_NOT_ENOUGH);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
}
