pragma solidity ^0.4.21;

import "./BaseVoting.sol";

contract RefundVoting is BaseVoting {

	uint public constant TERM = 4 weeks; //should be changed

    function RefundVoting(string _votingName) BaseVoting(_votingName) {
    	initialize(TERM);
    }
    
}