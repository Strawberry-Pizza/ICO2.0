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
        VOTE_TYPE voteType;
        uint256 round;
        bool isExist;
    }

    /* Global Variables */
    IERC20 public mToken;
    Fund public mFund;
    mapping(address => voteInfo) mVoteList; // {vote name => {voteAddress, voteType}}
    TapVoting public mTapVoting;
    RefundVoting public mRefundVoting;
    uint256 public mTapRound;
    uint256 public mRefundRound;
    VestingTokens public mVestingTokens;
    bool public switch__isTapVotingOpened = false;
    uint256 public constant REFRESH_TERM = 4 weeks;

    /* Events */
    event CreateTapVote(address indexed vote_account, VOTE_TYPE type_, uint256 indexed round, string name);
    event CreateRefundVote(address indexed vote_account, VOTE_TYPE type_, uint256 indexed round, string name);
    event DiscardTapVote(address indexed vote_account, VOTE_TYPE type_, uint256 indexed round, string name);
    event DiscardRefundVote(address indexed vote_account, VOTE_TYPE type_, uint256 indexed round, string name);

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
        mTapRound = 1;
        mRefundRound = 1;
        mVestingTokens = VestingTokens(_vestingTokensAddress);
        mFund.setVotingFactoryAddress(address(this));
    }

    function isVoteExist(address _votingAddress) view public
        returns(bool) {
            return mVoteList[_votingAddress].isExist;
    }

    //TODO: chop it
    function newVoting(
        string _votingName,
        VOTE_TYPE _vote_type,
        uint256 _term) public
        returns(address) {
            require(isVoteExist(_votingName));
            require(_vote_type != VOTE_TYPE.NONE);
            if(_vote_type == VOTE_TYPE.REFUND) {
                if(address(mRefundVoting) == address(0)) {
                    mRefundVoting = new RefundVoting(_votingName, address(mToken), address(mFund), address(mVestingTokens), address(members));
                    emit CreateRefundVote(address(mRefundVoting), _vote_type, mRefundRound, _votingName);
                    mRefundRound = mRefundRound.add(1);
                    return address(mRefundVoting);
                }
                else {
                    mRefundVoting = new RefundVoting(_votingName, address(mToken), address(mFund), address(mVestingTokens), address(members));
                    if(address(mRefundVoting) == 0x0) { revert("Refund voting has not created."); }
                    emit CreateRefundVote(address(mRefundVoting), _vote_type, mRefundRound, _votingName);
                    mRefundRound = mRefundRound.add(1);
                    return address(mRefundVoting);
                }
            }
            if(_vote_type == VOTE_TYPE.TAP && switch__isTapVotingOpened == false) {
                mTapvoting = new TapVoting(_votingName, address(mToken), address(mFund), address(mVestingTokens), address(members));
                if(address(mTapVoting) == 0x0) { revert("Tap voting has not created."); }
                switch__isTapVotingOpened = true;
                emit CreateTapVote(address(mTapVoting), _vote_type, mTapRound, _votingName);
                return address(mTapvoting);
            }
            return address(0);
    }

    //TODO: chop the destroyVoting into Tap and Refund voting
    function destroyVoting(,
        address _vote_account,
        string _vote_name,
        VOTE_TYPE _vote_type) public
        onlyDevelopers
        returns(bool) {
            require(isVoteExist(_vote_account));
            require(mVoteList[_vote_account].voteType == _vote_type);

            if(mVoteList[_vote_account].voteType == VOTE_TYPE.REFUND && address(mRefundVoting) != address(0)) { // Refund Voting Destroying
                emit DiscardTapVote(_vote_account, _vote_type, mVoteList[_vote_account].round, _vote_name); // TODO: _vote_name is not in mVoteList.
                mRefundvoting.discard();
            }
            else if(mVoteList[_votingName].voteType == VOTE_TYPE.TAP && switch__isTapVotingOpened == true) {
                mTapvoting = TapVoting(_vote_account);
                emit DestroyVote(_vote_account, _votingName, mVoteList[_votingName].voteType);
                mTapvoting.destroy();
                switch__isTapVotingOpened = false;
            }
            return true;
    }

    function refreshRefundVoting() public
        returns(bool) {
            //TODO
            //require(~~, "invalid time for refreshing Refund Voting.");
            require(address(mRefundvoting) != address(0), "has not already set refundvoting.");
            if(!mRefundvoting.discard()) {revert("cannot refresh refund voting");}
            newVoting("refund voting", VOTE_TYPE.REFUND, REFRESH_TERM);  
    }
}
