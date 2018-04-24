pragma solidity ^0.4.23;

import "./ERC20.sol";
import "../lib/SafeMath.sol";

contract BaseToken is ERC20 {
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].safeAdd(_addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.safeSub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
}