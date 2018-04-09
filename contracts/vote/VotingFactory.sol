/*
 * VotingFactory.sol is used for creating new voting instance.
 */

pragma solidity ^0.4.21;

import "./BaseVoting.sol";
import "./TapVoting.sol";
import "./RefundVoting.sol";

contract VotingFactory {

    event CreateNewVote(address indexed vote_account, string name, string type);
    event DestroyVote(address indexed vote_account, string name);

    function VotingFactory(){}
    function newVoting(string _votingName, bool isTapVoting) public returns(address) {
        BaseVoting v;
        if(isTapVoting){
            v = new TapVoting(_votingName);
        } else{
            v = new RefundVoting(_votingName);
        }
        emit CreateNewVote(address(v), _votingName);
        return address(v);
    }
    function destroyVoting(address vote_account) public onlyDevelopers returns(bool){
        require(vote_account != 0x0);
        BaseVoting v = BaseVoting(vote_account);
        emit DestroyVote(vote_account, v.getName());
        v.destroy();
        return true;
    }
}
