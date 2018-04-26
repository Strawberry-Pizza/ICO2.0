pragma solidity ^0.4.23;

import "../fund/Fund.sol";
import "../token/ERC20.sol";
import "../vote/TapVoting.sol";
import "../crowdsale/Crowdsale.sol";
import "../ownership/Ownable.sol";
import "../lib/SafeMath.sol";

contract IncentivePool is Ownable {
    using SafeMath for uint256;
    ERC20 public token;
    TapVoting public tapvoting;
    mapping(uint256 => TapVoting) prevTapVotingList;
    uint256 currentTapVotingNumber;

    constructor(address _token) public onlyDevelopers {
        token = ERC20(_token);
        currentTapVotingNumber = 0;
    }

    event ReceiveIncentive(uint256 indexed vote_number, address indexed receiver, uint256 incentive_amount);
    //TODO: must cover the previous tap voting incentive
    function getBalance() public view returns(uint256) {
        return this.balance;
    }
    function getToken() public view returns(address) {
        return address(token);
    }
    function getCurrentTapVoting() public view returns(address) {
        return address(tapvoting);
    }
    function getPrevTapVoting(uint256 _votingNumber) public view returns(address) {
        return address(prevTapVotingList[_votingNumber]);
    }
    function getIncentiveAmountPerOne(address account) public view returns(uint256) {
        //TODO: put the formula in this func
        uint256 token_amt = tapvoting.party_list[account].power;
    }
    function getPrevIncentiveAmountPerOne(uint256 _votingNumber, address account) public view returns(uint256) {
        //TODO: put the formula in this func
        uint256 token_amt = tapvoting.party_list[account].power;
    }
    function hasReceived(address account) public view returns(bool) {
        return tapvoting.party_list[account].isReceivedIncentive;
    }
    function hasPrevReceived(uint256 _votingNumber, address account) public view returns(bool) {
        return prevTapVotingList[_votingNumber].party_list[account].isReceivedIncentive;
    }

    function setTapVotingAddr(address _tapvoting) public onlyDevelopers returns(bool) {
        require(_tapvoting != 0x0);
        currentTapVotingNumber++;
        prevTapVotingList[currentTapVotingNumber] = TapVoting(_tapvoting);
        tapvoting = prevTapVotingList[currentTapVotingNumber];
        return true;
    }

    function withdraw() external returns (bool) {

    }
    /*
    the incentivised holder should call this function directly.
    */
    function receiveIncentiveItself() public returns(bool) {
        require(!hasReceived(msg.sender), "already received incentive");
        token.transferFrom(address(this), msg.sender, getIncentiveAmountPerOne(msg.sender));
        tapvoting.party_list[account].isReceivedIncentive = true;
        emit ReceiveIncentive(currentTapVotingNumber, msg.sender, getIncentiveAmountPerOne(msg.sender));
    }

    function receivePrevIncentiveItself(uint256 _votingNumber) public returns(bool) {
        require(!hasPrevReceived(_votingNumber, msg.sender), "already received incentive");
        token.transferFrom(address(this), msg.sender, getPrevIncentiveAmountPerOne(_votingNumber, msg.sender));
        prevTapVotingList[_votingNumber].party_list[account].isReceivedIncentive = true;
        emit ReceiveIncentive(_votingNumber, msg.sender, getPrevIncentiveAmountPerOne(_votingNumber, msg.sender));
    }


    /*
    function _sendIncentivePerOne(address account) internal returns(uint256) {
        //TODO: sender must be the contract
        token.transfer(account, getIncentiveAmountPerOne(account));
    }
    function sendIncentive() external onlyDevelopers returns(bool) {

        for(uint i=0; i<___.length; i++){
            _sendIncentivePerOne(___[i]);
        }
    }
    */
}
