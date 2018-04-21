pragma solidity ^0.4.23;

import "./BaseVoting.sol";

contract RefundVoting is BaseVoting {

	uint256 public constant TERM = 4 weeks; //should be changed

    constructor(string _votingName, address _tokenAddress) public BaseVoting(_votingName, _tokenAddress) {}
    function initialize(uint256 term) public returns(bool) {
    	super.initialize(TERM); //fixed term
    }
    function finalize() public returns (RESULT_STATE) {}
    function vote(bool agree) public returns (bool) {}
    function revoke() public returns (bool) {}

    //TODO: we should add(override) some meaningful function
}
