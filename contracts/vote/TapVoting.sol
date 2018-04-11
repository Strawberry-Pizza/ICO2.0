pragma solidity ^0.4.21;

import "./BaseVoting.sol";

contract TapVoting is BaseVoting {

	uint256 public constant MIN_TERM = 7 days; // should be changed
	uint256 public constant MAX_TERM = 2 weeks; // should be changed

    function TapVoting(string _votingName) BaseVoting(_votingName) {
    }
    //@Override
    function initialize(uint256 term) public returns(bool){
    	require(term > MIN_TERM && MAX_TERM > term);
    	super.initialize(term);
    }

    function openVoting() public returns(bool){
    	super.openVoting();
    }

    function closeVoting() public returns(bool){
    	super.closeVoting();
    }

}
