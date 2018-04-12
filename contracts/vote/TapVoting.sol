pragma solidity ^0.4.21;

import "./BaseVoting.sol";
import "../fund/Fund.sol";

contract TapVoting is BaseVoting {

	uint256 public constant MIN_TERM = 7 days; // should be changed
	uint256 public constant MAX_TERM = 2 weeks; // should be changed
    uint256 public constant DEV_POWER = 0.7;

    function TapVoting(string _votingName) BaseVoting(_votingName) {}

    function getTotalPower() view public returns(uint256) {
        //TODO: totalSupply(1-p) + totalSupply*p*DEV_POWER, p is dev ratio
        return 0;
    }
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
    function vote() public returns(bool agree) {
        super.vote();
        uint256 weight = 1;
        if(isDeveloper(msg.sender) == true){
            weight = DEV_POWER; // q
        }
        uint256 vote_power = SafeMath.safeMul(balanceOf[msg.sender], weight);
        if(agree) {
            party_list[msg.sender] = VOTESTATE.AGREE;
            agree_power = SafeMath.safeAdd(agree_power, vote_power);
        }
        else {
            party_list[msg.sender] = VOTESTATE.DISAGREE;
            disagree_power = SafeMath.safeAdd(disagree_power, vote_power);
        }
    }
    function revoke() public returns(bool) {
        super.revoke();
    }
    function finalize() public returns(bool) {
        super.finalize();
    }
    //TODO: we should add(override) some meaningful function



}
