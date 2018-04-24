pragma solidity ^0.4.23;

/**
 * @title IERC20 - ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */

contract IERC20 {
    function transfer(address _to, uint256 _value)  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function burn(uint256 _value) public returns (bool success);
    function freeze(uint256 _value) public returns (bool success);
    function unfreeze(uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
}
