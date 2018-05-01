pragma solidity ^0.4.23;

import "./BaseVoting.sol";
import "../fund/Fund.sol";

contract TapVoting is BaseVoting {
    /* Global Variables */
    uint256 public constant MIN_TERM = 7 days; // should be changed
    uint256 public constant MAX_TERM = 2 weeks; // should be changed
    uint256 public constant DEV_POWER = 70; // percent
    uint256 public constant DEV_PERC = 14; // percent
    uint256 public constant PUBLIC_TOKEN_PERC = 65; //FIXIT: it should be changed in every tap voting term and it is NOT constant, it means totalSupply() - locked_token - reserve_token
    /* Constructor */
    constructor(
        string _votingName,
        address _tokenAddress,
        address _fundAddress,
        address _membersAddress) BaseVoting(_votingName, _tokenAddress, _fundAddress, _membersAddress) public {
        //FIXIT: external...
        }
    /* View Function */
    function getTotalPower() view public returns(uint256) {
        // totalSupply(1-p) + totalSupply*p*DEV_POWER, p is dev ratio
        uint256 ret1 = token.totalSupply().mul(uint256(100).sub(DEV_PERC)).mul(100);
        uint256 ret2 = token.totalSupply().mul(DEV_PERC).mul(DEV_POWER);
        return ret1.add(ret2);
    }
    function getAgreePower() view public returns(uint256) {
        return agree_power;
    }
    function getDisagreePower() view public returns(uint256) {
        return disagree_power;
    }
    function getAbsentPower() view public returns(uint256) {
        uint256 voted_power = agree_power.add(disagree_power);
        return getTotalPower().sub(voted_power);
    }
    function getParticipatingPerc() view public returns(uint256) {
        uint256 total_token = token.totalSupply().mul(PUBLIC_TOKEN_PERC).div(100);
        uint256 participating_token = getAgreePower().add(getDisagreePower());
        return participating_token.mul(100).div(total_token);
    }
    function getMinVotingPerc() view public returns(uint256) {
        //TODO: it is affected by the previous tap voting's participating rate.
        return 20;
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
    function _snapshot() internal returns(bool){
        //FIXIT: how to reduce the snapshot operation gas fee?
        for(uint256 i = 1; i< index_party_list.add(1); i++) {
            uint256 weight = isDeveloper(party_list[i]) ? DEV_POWER : 100; // percent
            uint256 vote_power = token.balanceOf(party_list[i]).mul(weight).div(100);
            party_dict[party_list[i]].power = vote_power; //snapshot each account's vote power 
            if(party_dict[party_list[i]].state == VOTE_STATE.AGREE) {
                agree_power=agree_power.add(vote_power);
            } else if(party_dict[party_list[i]].state == VOTE_STATE.DISAGREE) {
                disagree_power=disagree_power.add(vote_power);
            }    // cumulate total power of agree and disagree parties.
        }
        return true;
    }

    function finalize() public returns(RESULT_STATE) {
        // pass the vote if yes - no > 0
        require(period == VOTE_PERIOD.CLOSED);
        RESULT_STATE result = RESULT_STATE.NONE;
        
        if(!_snapshot()){ revert("failed to snapshot in tap finalize."); }
        if(getParticipatingPerc() < getMinVotingPerc()){ revert("It cannot satisfy minimum voting rate."); }
        if(getAgreePower() > getDisagreePower()) {
            result = RESULT_STATE.PASSED;
        }
        else {
            result = RESULT_STATE.REJECTED;
        }
        period = VOTE_PERIOD.FINALIZED;
        emit FinalizeVote(msg.sender, now, result);
        if(!fund.withdrawFromFund()){ revert("failed to withdrawFromFund in tap finalize."); }
        return result;
    }
    /* Personal Voting function
     * vote, revoke
     */
    function vote(bool agree) public returns(bool) {
        return super.vote(agree);
    }

    function revoke() public returns(bool) {
        //TODO: need to be fixed
        require(isActivated());
        require(msg.sender != 0x0);
        require(party_dict[msg.sender].state != VOTE_STATE.NONE); // can vote only once

        uint256 vote_power = party_dict[msg.sender].power;
        //add sender to revoke_list(or count up)
        if(revoke_list[msg.sender] > 0) { revoke_list[msg.sender]++; }
        else { revoke_list[msg.sender] = 1; }
        //subtract the count that sender voted before
        if(party_dict[msg.sender].state == VOTE_STATE.AGREE){
            agree_power = agree_power.sub(vote_power);
        }
        else if(party_dict[msg.sender].state == VOTE_STATE.DISAGREE) {
            disagree_power = disagree_power.sub(vote_power);
        }
        //change the voter's state to NONE.
        party_dict[msg.sender].state = VOTE_STATE.NONE;
        return true;
    }

    //TODO: we should add(override) some meaningful function

}
