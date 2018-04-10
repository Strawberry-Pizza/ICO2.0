pragma solidity ^0.4.21;

import "./BaseToken.sol";
import "../ownership/Ownable.sol";
import "../vote/VotingFactory.sol";

contract CustomToken is BaseToken, Ownable {

	VotingFactory factory;

	function CustomToken(
        uint256 initialSupply,
        uint8 decimals_,
        string name_,
        string symbol_
        ) BaseToken(initialSupply, name_, symbol_, decimals_) public {
		factory = new VotingFactory(address(this));
    }

    //@Override
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if(super.transfer(_to, _value)){
        	
        }
    }
}