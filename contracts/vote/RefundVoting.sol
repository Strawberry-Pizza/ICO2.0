pragma solidity ^0.4.23;

import "./BaseVoting.sol";

contract RefundVoting is BaseVoting {

    //TODO:can enum type be overrided?
    enum VOTE_PERIOD {NONE, INITIALIZED, OPENED, CLOSED, FINALIZED, DISCARDED}

    uint256 public constant REFRESH_TERM = 4 weeks; //should be changed
    uint256 public discardTime;
    bool public isAvailable = true;

    event RefreshRefundVoting(uint256 indexed time);

    modifier available() {
        require(isAvailable, "this refund voting has been discarded.");
        _;
    }

    constructor(
        string _votingName,
        address _tokenAddress,
        address _fundAddress,
        address _vestingTokens,
        address _membersAddress
        ) BaseVoting(_votingName, _tokenAddress, _fundAddress, _vestingTokens, _membersAddress) public {
        isAvailable = true;
    }
    
    function canDiscard() public view
        returns(bool) {
            return (now >= endTime && now >= startTime.add(REFRESH_TERM));
    }
    
    /* RefundVoting Period Function
     * order: initialize -> open -> close -> finalize -> discard
     */
    function initializeVote() public
        period(VOTE_PERIOD.NONE)
        available
        returns(bool) {
            return super.initializeVote(REFRESH_TERM); //fixed term
    }
    
    function openVote() public
        period(VOTE_PERIOD.INITIALIZED)
        available
        returns(bool) {
            return super.openVote();
    }

    function closeVote() public
        period(VOTE_PERIOD.OPENED)
        available
        returns(bool) {
            return super.closeVote();
    }

    function finalizeVote() public
        period(VOTE_PERIOD.CLOSED) 
        available
        returns (RESULT_STATE) {
            
    }
    
    function discard() public
        period(VOTE_PERIOD.FINALIZED)
        available
        only(mFactoryAddress)
        returns(bool) {
            require(now >= endTime && now >= startTime.add(REFRESH_TERM), "check that refund voting is in the discardable state.");
            
            if(!_haltFunctions()) {revert("cannot discard the refund voting.");}
            
            discardTime = now;
            mPeriod = VOTE_PERIOD.DISCARDED;
            emit RefreshRefundVoting(discardTime);
            return true;
    }
    
    function _haltFunctions() internal
        available
        returns(bool) {
            isAvailable = false;
            return true;
    }
    /* Personal Voting function
     * vote, getBack
     */
    function vote(bool agree) public
        available
        returns (bool) {
            return super.vote(agree);
    }
    
    function getBack() public
        available
        returns (bool) {
            return super.getBack();
    }
    

}
