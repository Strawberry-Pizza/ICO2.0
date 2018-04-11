pragma solidity ^0.4.21;

import "./BaseVoting.sol";

contract RefundVoting is BaseVoting {

	uint256 public constant TERM = 4 weeks; //should be changed

    function RefundVoting(string _votingName) BaseVoting(_votingName) {}
    function initialize(uint256 term) external returns(bool) {
    	super.initialize(TERM); //fixed term
    }
    
    //TODO: we should add(override) some meaningful function
}
