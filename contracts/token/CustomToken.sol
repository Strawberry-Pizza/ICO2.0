/*withhold this contract*/

pragma solidity ^0.4.23;

import "./BaseToken.sol";
import "../ownership/Ownable.sol";

contract CustomToken is BaseToken{
    constructor() public {
        decimals = DECIMALS;     // Amount of decimals for display purposes
        name = TOKEN_NAME;    // Set the name for display purposes
        symbol = TOKEN_SYMBOL;        // Set the symbol for display purposes
        totalSupply_ = INITIAL_SUPPLY;    // Update total supply, 100 billion tokens
        balances[msg.sender] = totalSupply_;
        emit Transfer(0x0, msg.sender, totalSupply_);
    }
}
