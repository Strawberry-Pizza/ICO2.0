pragma solidity ^0.4.18;

import "../ownership/Ownable.sol";
import "../token/DAICO_ERC20.sol";
import "../token/Fund.sol";
import "../lib/SafeMath.sol";

contract Voting is Ownable, DAICO_ERC20 {
    using SafeMath for uint256;

    string public votingName;
    bool public isInitialized = false;
    bool public isFinalized = false;
    uint256 public startTime;
    uint256 public endTime;
    
    uint256 public total_party = 0;
    uint256 public agree_party = 0;
    uint256 public disagree_party = 0;
    enum VOTESTATE {NONE, AGREE, DISAGREE};
    mapping(address=>VOTESTATE) public party_list;
    mapping(address=>uint256) public revoke_list; //account=>revoke count

    /* EVENTS */
    event InitializeVote(address indexed vote_account, string indexed voting_name, uint256 startTime, uint256 endTime);
    /* CONSTRUCTOR */
    function Voting(string _votingName) public {
        votingName = _votingName;
    }
    /*VIEW FUNCTION*/
    function isActivated() public view returns(bool) {
        return (isInitialized && !isFinalized);
    }
    function getInfo() public view returns(struct); //TODO
    function getName() public view returns(string){
        return votingName;
    }

    /*FUNCTION*/
    function initiative() public returns(bool) {
        require(!isInitialized);
        isInitialized = true;
        startTime = now;
        endTime = now + alpha; // you should change the alpha into proper value.
        InitializeVote(address(this), votingName, startTime, endTime);
        return true;
    }
    function vote() public returns(bool agree) { 
        require(msg.sender != 0x0);
        require(party_list[msg.sender] == VOTESTATE.NONE); // can vote only once
        uint256 memory votePower = 1;
        if (revoke_list[msg.sender] > 0) { votePower = 0.5**revoke_list[msg.sender]; }
        if(agree) {
            party_list[msg.sender] = VOTESTATE.AGREE;
            agree_party += votePower;
            total_party += votePower;
        }
        else {
            party_list[msg.sender] = VOTESTATE.DISAGREE;
            disagree_party += votePower;
            total_party += votePower;
        }
    }
    function revoke() public returns(bool) {
        require(msg.sender != 0x0);
        require(party_list[msg.sender] != VOTESTATE.NONE); // can vote only once
        uint256 memory votePower = 0.5**revoke_list[msg.sender];
        //add sender to revoke_list(or count up)
        if(revoke_list[msg.sender] > 0) { revoke_list[msg.sender]++; }
        else { revoke_list[msg.sender] = 1; }
        //subtract the count that sender voted before
        if(party_list[msg.sender] == VOTESTATE.AGREE){
            agree_party -= votePower;
            total_party -= votePower;
        }
        else if(party_list[msg.sender] == VOTESTATE.DISAGREE) {
            disagree_party -= votePower;
            total_party -= votePower;
        }
        //change the voter's state to NONE.
        party_list[msg.sender] = VOTESTATE.NONE;
        return true;
    }

    function finalize() public returns(bool);
    function _clearVariables() public returns(bool); // clean vars after finalizing prev voting.
    function destroy() external onlyDevelopers returns(bool){
        require(isFinalized);
        selfdestruct(address(this));
        return true;
    }
}

contract TapVoting is Voting {
//
    function TapVoting(string _votingName) Voting(_votingName) {} 
}

contract BufferVoting is Voting {
//
    function BufferVoting(string _votingName) Voting(_votingName) {} 
}



