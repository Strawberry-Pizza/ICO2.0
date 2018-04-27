/*withhold this contract*/

pragma solidity ^0.4.23;

import "./BaseToken.sol";
import "../ownership/Ownable.sol";

contract CustomToken is BaseToken{
	constructor() public {
        decimals = 18;     // Amount of decimals for display purposes
        name = "CUSTOM";    // Set the name for display purposes
        symbol = "CTM";        // Set the symbol for display purposes
        totalSupply_ = 100 * (1000 ** 3) * (10**uint256(decimals));    // Update total supply, 100 billion tokens
        balances[msg.sender] = totalSupply_;
        emit Transfer(0x0, msg.sender, totalSupply_);
    }
}
