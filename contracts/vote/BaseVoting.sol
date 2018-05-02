pragma solidity ^0.4.23;

import "../token/ERC20.sol";
import "../fund/Fund.sol";
import "../lib/SafeMath.sol";
import "../token/VestingTokens.sol";
import "../ownership/Ownable.sol";

contract BaseVoting is Ownable {
    /*Library and Typedefs*/
    using SafeMath for uint256;

    enum VOTE_PERIOD {NONE, INITIALIZED, OPENED, CLOSED, FINALIZED}
    enum VOTE_STATE {NONE, AGREE, DISAGREE}
    enum RESULT_STATE {NONE, PASSED, REJECTED}

    struct vote_receipt {
        VOTE_STATE state;
        uint256 power;
        bool isReceivedIncentive;
    }


    
    /* Global Variables */
    string public mVotingName;
    VOTE_PERIOD mPeriod;
    ERC20 public mToken;
    Fund public mFund;
    VestingTokens public mVestingTokens;
    address public mFactoryAddress;

    uint public minVotePerc;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public agree_power = 0; // real value is divided by 100(weight)
    uint256 public disagree_power = 0;

    mapping(address => vote_receipt) public party_dict;
    address[] public party_list;
    
    /* comment by @JChoy
        why do we need revoke_list and index_party_list?
        at Issue #4
    */


    /* Events */
    event InitializeVote(address indexed vote_account, string indexed voting_name, uint256 startTime, uint256 endTime);
    event OpenVoting(address indexed opener, uint256 open_time);
    event CloseVoting(address indexed closer, uint256 close_time);
    event FinalizeVote(address indexed finalizer, uint256 finalize_time, RESULT_STATE result);



    /* Modifiers */
    modifier onlyVotingFactory() {
        require(msg.sender == mFactoryAddress);
        _;
    }



    /* Constructor */
    constructor(
        string _votingName,
        address _tokenAddress,
        address _fundAddress,
        address _vestingTokensAddress,
        address _membersAddress
        ) public Ownable(_membersAddress) {
        require(_tokenAddress != address(0));
        require(_fundAddress != address(0));
        require(_vestingTokensAddress != address(0));
        require(_membersAddress != 0x0);

        mVotingName = _votingName;
        mToken = ERC20(_tokenAddress);
        mFund = Fund(_fundAddress);
        mVestingTokens = VestingTokens(_vestingTokensAddress);
        mPeriod = VOTE_PERIOD.NONE;
        mFactoryAddress = msg.sender; // It should be called by only VotingFactory
    }



    /* View Function */
    function isActivated() public view returns(bool) {
        return (mPeriod == VOTE_PERIOD.OPENED);
    }
    //function getInfo() public view returns(string); //TODO
    function getName() public view returns(string){ return mVotingName; }
    function getTotalParty() public view returns(uint256) {
        return agree_power.add(disagree_power);
    }
    function readPartyDict(address account) public view returns(VOTE_STATE, uint256, bool) {
        return (party_dict[account].state, party_dict[account].power, party_dict[account].isReceivedIncentive);
    }
    function writePartyDict(address account, VOTE_STATE a, uint256 b, bool c) public returns(bool) {
        if(a != VOTE_STATE.NONE) {party_dict[account].state = a;}
        if(b != 0) {party_dict[account].power = b;}
        if(c != false) {party_dict[account].isReceivedIncentive = true;}
        return true;
    }



    /* Voting Period Function
     * order: initialize -> open -> close -> finalize
     */
    function initialize(uint256 _term) public returns(bool) {
        require(mPeriod == VOTE_PERIOD.NONE);
        require(msg.sender != 0x0);

        startTime = now;
        endTime = now + _term; // you should change the alpha into proper value.
        mPeriod = VOTE_PERIOD.INITIALIZED;
        emit InitializeVote(address(this), mVotingName, startTime, endTime);
        return true;
    }
    function openVoting() public returns(bool){
        require(mPeriod == VOTE_PERIOD.INITIALIZED);

        mPeriod = VOTE_PERIOD.OPENED;
        emit OpenVoting(msg.sender, now);
        return true;
    }
    function closeVoting() public returns(bool){
        require(now >= endTime);
        require(mPeriod == VOTE_PERIOD.OPENED);

        mPeriod = VOTE_PERIOD.CLOSED;
        emit CloseVoting(msg.sender, now);
        return true;
    }
    //TODO: specify the condition of finality
    function finalize() public returns(RESULT_STATE) { return RESULT_STATE.NONE; }



    /* Personal Voting function
     * vote, revoke
     */
    function vote(bool _agree) public returns(bool) {    
        require(isActivated());
        require(msg.sender != 0x0);
        require(party_dict[msg.sender].state == VOTE_STATE.NONE); // can vote only once
        if(_agree) {
            party_dict[msg.sender].state = VOTE_STATE.AGREE;
        }
        else {
            party_dict[msg.sender].state = VOTE_STATE.DISAGREE;
        }
        return true;
    }
    //TODO: not implemented yet
    function revoke() public returns(bool) { return false; }



    /* Destroy function */
    //TODO: no need?
    // function _clearVariables() public returns(bool); // clean vars after finalizing prev voting.
    function destroy() external onlyVotingFactory returns(bool){
        require(mPeriod == VOTE_PERIOD.FINALIZED);
        selfdestruct(address(this));
        return true;
    }
}



