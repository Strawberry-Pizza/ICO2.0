/*withhold this contract*/

pragma solidity ^0.4.23;

import "./BaseToken.sol";
import "../ownership/Ownable.sol";

contract CustomToken is BaseToken{
	constructor(
        uint256 _initialSupply,
        uint8 _decimals,
        string _name,
        string _symbol
        ) public {
        totalSupply = _initialSupply;                        // Update total supply
        decimals = _decimals;                            // Amount of decimals for display purposes
        name = _name;                                   // Set the name for display purposes
        symbol = _symbol;                               // Set the symbol for display purposes
        owner = msg.sender;
    }
}
