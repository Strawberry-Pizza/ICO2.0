pragma solidity ^0.4.23;

import "./BaseVoting.sol";

contract RefundVoting is BaseVoting {

	uint256 public constant TERM = 4 weeks; //should be changed

    constructor(string _votingName, address _tokenAddress, address _fundAddress) BaseVoting(_votingName, _tokenAddress, _fundAddress) external {}
    function initialize(uint256 term) public returns(bool) {
    	super.initialize(TERM); //fixed term
    }
    function finalize() public returns (RESULT_STATE) {}
    function vote(bool agree) public returns (bool) {}
    function revoke() public returns (bool) {}

    //TODO: we should add(override) some meaningful function
}
