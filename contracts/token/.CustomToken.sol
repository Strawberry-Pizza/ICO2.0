/*withhold this contract*/

pragma solidity ^0.4.21;

import "../token/ERC20.sol";
import "../ownership/Ownable.sol";

contract CustomToken is ERC20, Ownable {
	function CustomToken(
        uint256 initialSupply,
        uint8 decimals_,
        string name_,
        string symbol_
        ) public ERC20(initialSupply, decimals_, name_, symbol_) {}

    function transfer(address _to, uint256 _value) public returns (bool success) {}
}
