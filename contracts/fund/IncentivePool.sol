pragma solidity ^0.4.23;

import "../fund/Fund.sol";
import "../token/ERC20.sol";
import "../vote/TapVoting.sol";
import "../crowdsale/Crowdsale.sol";
import "../ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

contract IncentivePool is Ownable {
    using SafeMath for uint256;
    ERC20 public token;
    TapVoting public tapvoting;
    mapping(uint256 => address) prevTapVotingList;
    uint256 currentTapVotingNumber;

    constructor(address _token) public onlyDevelopers {
        token = ERC20(_token);
        currentTapVotingNumber = 0;
    }

    function getToken() public view returns(address) {
        return address(token);
    }
    function getTapVoting() public view returns(address) {
        return address(tapvoting);
    }
    function getIncentiveAmountPerOne(address account) public view returns(uint256) {
        //TODO: put the formula in this func
        uint256 token_amt = tapvoting.party_list[account].power;
    }
    function HasReceived(address account) public view returns(bool) {
        return tapvoting.party_list[account].isReceivedIncentive;
    }

    function setTapVotingAddr(address _tapvoting) public onlyDevelopers returns(bool) {
        require(_tapvoting != 0x0);
        tapvoting = TapVoting(_tapvoting);
        currentTapVotingNumber++;
        prevTapVotingList[currentTapVotingNumber] = _tapvoting;
        return true;
    }

    function withdraw() external returns (bool) {

    }
    /*
    the incentivised holder should call this function directly.
    */
    function receiveIncentiveItself() public returns(bool) {
        require(!HasReceived(msg.sender), "already received incentive");
        token.transferFrom(address(this), msg.sender, getIncentiveAmountPerOne(msg.sender));
        tapvoting.party_list[account].isReceivedIncentive = true;
        emit ReceiveIncentive(address(this), msg.sender, getIncentiveAmountPerOne(msg.sender));
    }

    function _sendIncentivePerOne(address account) internal returns(uint256) {
        //TODO: sender must be the contract
        token.transfer(account, getIncentiveAmountPerOne(account));
    }
    function sendIncentive() external onlyDevelopers returns(bool) {

        for(uint i=0; i<___.length; i++){
            _sendIncentivePerOne(___[i]);
        }
    }

}
