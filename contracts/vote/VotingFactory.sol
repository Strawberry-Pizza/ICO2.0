/*
 * VotingFactory.sol is used for creating new voting instance.
 */

pragma solidity ^0.4.23;

import "../token/ERC20.sol";
import "../token/IERC20.sol";
import "../fund/Fund.sol";
import "./BaseVoting.sol";
import "./TapVoting.sol";
import "./RefundVoting.sol";
import "../ownership/Ownable.sol";

contract VotingFactory is Ownable {
    /* Typedefs */
    enum VOTE_TYPE {NONE, REFUND, TAP}
    struct voteInfo {
        address voteAddress;
        VOTE_TYPE voteType;
        bool isExist;
    }
    /* Global Variables */
    IERC20 public token;
    Fund public fund;
    mapping(string => voteInfo) voteList; // {vote name => {voteAddress, voteType}}
    RefundVoting public refundvoting;
    bool public switch__isTapVotingOpened = false;

    /* Events */
    event CreateNewVote(address indexed vote_account, string indexed name, VOTE_TYPE type_);
    event DestroyVote(address indexed vote_account, string indexed name, VOTE_TYPE type_);

    /* Constructor */
    //call when Crowdsale finished
    constructor(address _tokenAddress, address _fundAddress) public onlyDevelopers {
        require(_tokenAddress != 0x0);
        require(_fundAddress != 0x0);

        token = IERC20(_tokenAddress);
        fund = Fund(_fundAddress);
        fund.setVotingFactoryAddress(address(this));
    }
    function isVoteExist(string _votingName) view public returns(bool) {
        return voteList[_votingName].isExist;
    }
    function newVoting(string _votingName, VOTE_TYPE vote_type, uint256 term) public returns(address) {
        require(isVoteExist(_votingName));
        require(vote_type != VOTE_TYPE.NONE);
        if(vote_type == VOTE_TYPE.REFUND && address(refundvoting) == 0x0) {
            refundvoting = new RefundVoting(_votingName, address(token), address(fund));
            refundvoting.initialize(term);
            emit CreateNewVote(address(refundvoting), _votingName, vote_type);
            return address(v_ref);
        }
        if(vote_type == VOTE_TYPE.TAP && switch__isTapVotingOpened == false) {
            TapVoting v_tap = new TapVoting(_votingName, address(token), address(fund));
            v_tap.initialize(term);
            switch__isTapVotingOpened = true;
            emit CreateNewVote(address(v_tap), _votingName, vote_type);
            return address(v_tap);
        }
        return address(0);
    }

    function destroyVoting(string _votingName, address vote_account) public onlyDevelopers returns(bool){
        require(vote_account != 0x0);
        require(isVoteExist(_votingName));
        require(voteList[_votingName].voteAddress == vote_account);

        if(voteList[_votingName].voteType == VOTE_TYPE.REFUND && address(refundvoting) != 0x0) {
            emit DestroyVote(vote_account, _votingName, voteList[_votingName].voteType);
            refundvoting.destroy();
        }
        else if(voteList[_votingName].voteType == VOTE_TYPE.TAP && switch__isTapVotingOpened == true) {
           TapVoting v_tap = TapVoting(vote_account);
           emit DestroyVote(vote_account, _votingName, voteList[_votingName].voteType);
           v_tap.destroy();
           switch__isTapVotingOpened = false;
        }
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
