/*
 * VotingFactory.sol is used for creating new voting instance.
 */

pragma solidity ^0.4.21;

import "./Voting.sol";

contract VotingFactory {

    event CreateNewVote(address indexed vote_account, string name);
    event DestroyVote(address indexed vote_account, string name);

    function VotingFactory(){}
    function newVoting(string _votingName) public returns(address) {
        Voting v = (new Voting(_votingName));
        emit CreateNewVote(address(v), _votingName);
        return address(v);
    }
    function destroyVoting(address vote_account) public onlyDevelopers returns(bool){
        require(vote_account != 0x0);
        Voting v = Voting(vote_account);
        emit DestroyVote(vote_account, v.getName());
        v.destroy();
        return true;
    }
}
