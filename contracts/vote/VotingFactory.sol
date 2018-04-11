/*
 * VotingFactory.sol is used for creating new voting instance.
 */

pragma solidity ^0.4.21;

import "../token/BaseToken.sol"
import "../token/IERC20.sol"
import "./BaseVoting.sol";
import "./TapVoting.sol";
import "./RefundVoting.sol";
import "../ownership/Ownable.sol"

contract VotingFactory is Ownable {

    IERC20 token;
    enum VOTE_TYPE {REFUND, TAP};
    struct voteInfo {
        address voteAddress;
        VOTE_TYPE voteType;
        bool isExist;
    }
    mapping(string => voteInfo) voteList; // {vote name => {voteAddress, voteType}}

    event CreateNewVote(address indexed vote_account, string indexed name, VOTE_TYPE type);
    event DestroyVote(address indexed vote_account, string indexed name, VOTE_TYPE type);

    //call when Crowdsale finished
    function VotingFactory(address _tokenAddress) public {
        token = IERC20(_tokenAddress);
    }
    function isVoteExist(string _votingName) view public returns(bool) {
        return voteList[_votingName].isExist;
    }
    function newVoting(string _votingName, VOTE_TYPE vote_type, uint256 term) public returns(address) {
        require(isVoteExist(_votingName));

        if(vote_type == VOTE_TYPE.REFUND) {
            RefundVoting v = new RefundVoting(_votingName);
            v.initialize(term);
        } 
        else if(vote_type == VOTE_TYPE.TAP) {
            TapVoting v = new TapVoting(_votingName);
            v.initialize(term);
        }
        emit CreateNewVote(address(v), _votingName, vote_type);
        return address(v);
    }

    function destroyVoting(string _votingName, address vote_account) public onlyDevelopers returns(bool){
        require(vote_account != 0x0);
        require(isVoteExist(_votingName));
        require(voteList[_votingName].voteAddress == vote_account);

        if(voteList[_votingName].voteType == VOTE_TYPE.REFUND) {
            RefundVoting v = RefundVoting(vote_account);
            v.destroy();
        }
        else if(voteList[_votingName].voteType == VOTE_TYPE.TAP) {
           TapVoting v = TapVoting(vote_account);
           v.destroy();
        }
        emit DestroyVote(vote_account, v.getName(), voteList[v.getName()].voteType);
        return true;
    }
    /*
    function startVoting(uint term) public {
        if(tapVoting.initialize(term))
            tapVoting.openVoting();
    }
    function endVoting() public{
        tapVoting.closeVoting();
    }
    */
}
