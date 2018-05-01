pragma solidity ^0.4.23;

import "./BaseVoting.sol";

contract RefundVoting is BaseVoting {

	uint256 public constant REFRESH_TERM = 4 weeks; //should be changed
    uint256 public lastRefreshTime;

    event RefreshRefundVoting(uint256 indexed time);

    constructor(string _votingName, address _tokenAddress, address _fundAddress, address _membersAddress) BaseVoting(_votingName, _tokenAddress, _fundAddress, _membersAddress) public {}
    
    function canRefresh() public view returns(bool) {
        return (now >= lastRefreshTime.add(REFRESH_TERM));
    }
    
    function initialize(uint256 term) public returns(bool) {
    	super.initialize(REFRESH_TERM); //fixed term
    }
    function finalize() public returns (RESULT_STATE) { 
    }
    function vote(bool agree) public returns (bool) {
        return super.vote(agree);
    }
    function revoke() public returns (bool) {
    //TODO
    }
    function refresh() external onlyVotingFactory returns(bool) {
        require(now >= REFRESH_TERM.add(lastRefreshTime), "check that refund voting is in the refreshable state.");
        
        if(!_clearVariables()) { revert("cannot clear the refund voting."); }
        if(!_reinitVariables()) { revert("cannot reinitialize the refund voting."); }
        lastRefreshTime = now;
        emit RefreshRefundVoting(now);
        return true;
    }
    
    function _clearVariables() internal returns(bool) {
    //TODO
    }

    function _reinitVariables() internal returns(bool) {
    //TODO
    }
    //TODO: we should add(override) some meaningful function
}
