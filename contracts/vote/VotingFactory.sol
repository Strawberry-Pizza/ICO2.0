/*
 * VotingFactory.sol is used for creating new voting instance.
 */

pragma solidity ^0.4.23;

import "../token/IERC20.sol";
import "../fund/Fund.sol";
import "./BaseVoting.sol";
import "./TapVoting.sol";
import "./RefundVoting.sol";
import "../ownership/Ownable.sol";
import "../token/VestingTokens.sol";

contract VotingFactory is Ownable {

    /* Typedefs */
    enum VOTE_TYPE {NONE, REFUND, TAP}

    struct voteInfo {
        address voteAddress;
        VOTE_TYPE voteType;
        bool isExist;
    }



    /* Global Variables */
    IERC20 public mToken;
    Fund public mFund;
    mapping(string => voteInfo) mVoteList; // {vote name => {voteAddress, voteType}}
    TapVoting public mTapvoting;
    RefundVoting public mRefundvoting;
    VestingTokens public mVestingTokens;
    bool public switch__isTapVotingOpened = false;

    /* Events */
    event CreateNewVote(address indexed vote_account, string indexed name, VOTE_TYPE type_);
    event DestroyVote(address indexed vote_account, string indexed name, VOTE_TYPE type_);

    /* Constructor */
    //call when Crowdsale finished
    constructor(
        address _tokenAddress,
        address _fundAddress,
        address _vestingTokensAddress,
        address _membersAddress
        ) public Ownable(_membersAddress) {
        require(_tokenAddress != address(0));
        require(_fundAddress != address(0));
        require(_membersAddress != address(0));
        require(_vestingTokensAddress != address(0));

        mToken = IERC20(_tokenAddress);
        mFund = Fund(_fundAddress);
        mVestingTokens = VestingTokens(_vestingTokensAddress);
        mFund.setVotingFactoryAddress(address(this));
    }


    function isVoteExist(string _votingName) view public returns(bool) {
        return mVoteList[_votingName].isExist;
    }


    function newVoting(string _votingName, VOTE_TYPE _vote_type, uint256 _term) public returns(address) {
        require(isVoteExist(_votingName));
        require(_vote_type != VOTE_TYPE.NONE);
        if(_vote_type == VOTE_TYPE.REFUND && address(mRefundvoting) == address(0)) {
            mRefundvoting = new RefundVoting(_votingName, address(mToken), address(mFund), address(mVestingTokens));
            mRefundvoting.initialize(_term);
            emit CreateNewVote(address(mRefundvoting), _votingName, _vote_type);
            return address(mRefundvoting);
        }
        if(_vote_type == VOTE_TYPE.TAP && switch__isTapVotingOpened == false) {
            mTapvoting = new TapVoting(_votingName, address(mToken), address(mFund), address(mVestingTokens));
            mTapvoting.initialize(_term);
            switch__isTapVotingOpened = true;
            emit CreateNewVote(address(mTapvoting), _votingName, _vote_type);
            return address(mTapvoting);
        }
        return address(0);
    }

    function destroyVoting(string _votingName, address _vote_account) public onlyDevelopers returns(bool){
        require(_vote_account != address(0));
        require(isVoteExist(_votingName));
        require(mVoteList[_votingName].voteAddress == _vote_account);

        if(mVoteList[_votingName].voteType == VOTE_TYPE.REFUND && address(mRefundvoting) != address(0)) {
            emit DestroyVote(_vote_account, _votingName, mVoteList[_votingName].voteType);
            mRefundvoting.destroy();
        }
        else if(mVoteList[_votingName].voteType == VOTE_TYPE.TAP && switch__isTapVotingOpened == true) {
           mTapvoting = TapVoting(_vote_account);
           emit DestroyVote(_vote_account, _votingName, mVoteList[_votingName].voteType);
           mTapvoting.destroy();
           switch__isTapVotingOpened = false;
        }
        return true;
    }

    function refreshRefundVoting() public returns(bool) {
        //TODO
        //require(~~, "invalid time for refreshing Refund Voting.");
        require(address(mRefundvoting) != address(0), "has not already set refundvoting.");
        if(!mRefundvoting.refresh()) { revert("cannot refresh refund voting"); }
    }
}
