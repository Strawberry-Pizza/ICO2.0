pragma solidity ^0.4.21;

import "./BaseVoting.sol";
import "../fund/Fund.sol";

contract TapVoting is BaseVoting {
    /* Global Variables */
	uint256 public constant MIN_TERM = 7 days; // should be changed
	uint256 public constant MAX_TERM = 2 weeks; // should be changed
    uint256 public constant DEV_POWER = 70; // percent
    /* Constructor */
    function TapVoting(string _votingName, address _tokenAddress) BaseVoting(_votingName, _tokenAddress) public {
    }
    /* View Function */
    function getTotalPower() view public returns(uint256) {
        //TODO: totalSupply(1-p) + totalSupply*p*DEV_POWER, p is dev ratio
        return 0;
    }
    function getAbsentPower() view public returns(uint256) {
        uint256 voted_power = SafeMath.safeAdd(agree_power, disagree_power);
        return SafeMath.safeSub(getTotalPower(), voted_power);
    }

    /* Voting Period Function
     * order: initialize -> open -> close -> finalize
     */
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
    function finalize() public returns(RESULT_STATE) {
        //TODO: pass the vote if yes - no - absent/n > 0
        require(period == VOTE_PERIOD.CLOSED);

        RESULT_STATE result = RESULT_STATE.NONE;
        uint256 agree = agree_power;
        uint256 absent = SafeMath.safeDiv(getAbsentPower(), ABSENT_N);
        uint256 disagree = SafeMath.safeAdd(disagree_power, absent);
        if(agree > disagree) {
            result = RESULT_STATE.PASSED;
        }
        else {
            result = RESULT_STATE.REJECTED;
        }
        period = VOTE_PERIOD.FINALIZED;
        emit FinalizeVote(msg.sender, now, result);
        return result;
    }
    /* Personal Voting function
     * vote, revoke
     */
    function vote(bool agree) public returns(bool) {
        require(isActivated());
        require(msg.sender != 0x0);
        require(party_list[msg.sender].state == VOTE_STATE.NONE); // can vote only once

        uint256 weight = 100; // percent
        if(isDeveloper(msg.sender) == true){
            weight = DEV_POWER; // reducing vote power if sender is developer
        }
        uint256 vote_power = SafeMath.safeMul(token.getBalanceOf(msg.sender), weight);
        if(agree) {
            party_list[msg.sender].state = VOTE_STATE.AGREE;
            party_list[msg.sender].power = vote_power;
            agree_power = SafeMath.safeAdd(agree_power, vote_power);
        }
        else {
            party_list[msg.sender].state = VOTE_STATE.DISAGREE;
            party_list[msg.sender].power = vote_power;
            disagree_power = SafeMath.safeAdd(disagree_power, vote_power);
        }
        return true;
    }

    function revoke() public returns(bool) {
        //TODO: need to be fixed
        require(isActivated());
        require(msg.sender != 0x0);
        require(party_list[msg.sender].state != VOTE_STATE.NONE); // can vote only once

        uint256 vote_power = party_list[msg.sender].power;
        //add sender to revoke_list(or count up)
        if(revoke_list[msg.sender] > 0) { revoke_list[msg.sender]++; }
        else { revoke_list[msg.sender] = 1; }
        //subtract the count that sender voted before
        if(party_list[msg.sender].state == VOTE_STATE.AGREE){
            agree_power = SafeMath.safeSub(agree_power, vote_power);
        }
        else if(party_list[msg.sender].state == VOTE_STATE.DISAGREE) {
            disagree_power = SafeMath.safeSub(disagree_power, vote_power);
        }
        //change the voter's state to NONE.
        party_list[msg.sender].state = VOTE_STATE.NONE;
        return true;
    }

    //TODO: we should add(override) some meaningful function

}
