pragma solidity ^0.4.23;

import "../token/ERC20.sol";
import "../fund/Fund.sol";
import "../lib/SafeMath.sol";
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
    string public votingName;
    VOTE_PERIOD period;
    ERC20 public token;
    Fund public fund;
    address public factoryAddress;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public agree_power = 0; // real value is divided by 100(weight)
    uint256 public disagree_power = 0;
    uint256 public absent_power; //how can we count the number of whole member?
    uint256 public constant ABSENT_N = 6;
    mapping(address=>vote_receipt) public party_dict;
    mapping(uint256=>address) public party_list;
    uint256 public index_party_list = 0;
    mapping(address=>uint256) public revoke_list; //account=>revoke count
    /* Events */
    event InitializeVote(address indexed vote_account, string indexed voting_name, uint256 startTime, uint256 endTime);
    event OpenVoting(address indexed opener, uint256 open_time);
    event CloseVoting(address indexed closer, uint256 close_time);
    event FinalizeVote(address indexed finalizer, uint256 finalize_time, RESULT_STATE result);
    /* Modifiers */
    modifier onlyVotingFactory() {
        require(msg.sender == factoryAddress);
        _;
    }

    /* Constructor */
    constructor(string _votingName, address _tokenAddress, address _fundAddress, address _membersAddress) public Ownable(_membersAddress) {
        //FIXIT: only by VotingFactory
        require(_membersAddress != 0x0);
        votingName = _votingName;
        token = ERC20(_tokenAddress);
        period = VOTE_PERIOD.NONE;
        fund = Fund(_fundAddress);
        factoryAddress = msg.sender; // It should be called by only VotingFactory
    }
    /* View Function */
    function isActivated() public view returns(bool) {
        return (period == VOTE_PERIOD.OPENED);
    }
    //function getInfo() public view returns(string); //TODO
    function getName() public view returns(string){ return votingName; }
    function getTotalParty() public view returns(uint256) {
        return agree_power.add(disagree_power);
    }
    function readPartyDict(address account) public view returns(VOTE_STATE, uint256, bool) {
        return (party_dict[account].state, party_dict[account].power, party_dict[account].isReceivedIncentive);
     }
     function writePartyDict(address account, VOTE_STATE a, uint256 b, bool c) external returns(bool) {
         if(a != VOTE_STATE.NONE) { party_dict[account].state = a; }
         if(b != 0) { party_dict[account].power = b; }
         if(c != false) { party_dict[account].isReceivedIncentive = true; }
         return true;
     }

    /* Voting Period Function
     * order: initialize -> open -> close -> finalize
     */
    function initialize(uint256 term) public returns(bool) {
        require(period == VOTE_PERIOD.NONE);
        require(msg.sender != 0x0);

        startTime = now;
        endTime = now + term; // you should change the alpha into proper value.
        period = VOTE_PERIOD.INITIALIZED;
        emit InitializeVote(address(this), votingName, startTime, endTime);
        return true;
    }
    function openVoting() public returns(bool){
        require(period == VOTE_PERIOD.INITIALIZED);

        period = VOTE_PERIOD.OPENED;
        emit OpenVoting(msg.sender, now);
        return true;
    }
    function closeVoting() public returns(bool){
        require(now >= endTime);
        require(period == VOTE_PERIOD.OPENED);

        period = VOTE_PERIOD.CLOSED;
        emit CloseVoting(msg.sender, now);
        return true;
    }
    //TODO: specify the condition of finality
    function finalize() public returns(RESULT_STATE) { return RESULT_STATE.NONE; }

    /* Personal Voting function
     * vote, revoke
     */
    function vote(bool agree) public returns(bool) {    
        require(isActivated());
        require(msg.sender != 0x0);
        require(party_dict[msg.sender].state == VOTE_STATE.NONE); // can vote only once
        if(agree) {
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
        require(period == VOTE_PERIOD.FINALIZED);
        selfdestruct(address(this));
        return true;
    }
}



