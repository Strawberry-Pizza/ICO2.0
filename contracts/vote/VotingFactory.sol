/*
 * VotingFactory.sol is used for creating new voting instance.
 */

pragma solidity ^0.4.21;

import "../token/BaseToken.sol"
import "./BaseVoting.sol";
import "./TapVoting.sol";
import "./RefundVoting.sol";
import "../ownership/Ownable.sol"

contract VotingFactory is Ownable {

    BaseToken token;
    TapVoting tapVoting;
    RefundVoting refundVoting;

    event CreateNewVote(address indexed vote_account, string name, string type);
    event DestroyVote(address indexed vote_account, string name);


    //call when Crowdsale finished
    function VotingFactory(address _tokenAddress){
        token = BaseToken(_tokenAddress);
        tapVoting = new TapVoting("TapVoting");
        refundVoting = new RefundVoting("RefundVoting");
    }
    // function newVoting(string _votingName, bool isTapVoting) public returns(address) {
    //     BaseVoting v;
    //     if(isTapVoting){
    //         v = new TapVoting(_votingName);
    //     } else{
    //         v = new RefundVoting(_votingName);
    //     }
    //     emit CreateNewVote(address(v), _votingName);
    //     return address(v);
    // }
    // function destroyVoting(address vote_account) public onlyDevelopers returns(bool){
    //     require(vote_account != 0x0);
    //     BaseVoting v = BaseVoting(vote_account);
    //     emit DestroyVote(vote_account, v.getName());
    //     v.destroy();
    //     return true;
    // }

    function startVoting(uint term) public {
        if(tapVoting.initialize(term))
            tapVoting.openVoting();
    }

    function endVoting() public{
        tapVoting.closeVoting();
    }

}
