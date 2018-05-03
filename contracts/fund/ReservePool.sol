pragma solidity ^0.4.23;

import "../fund/Fund.sol";
import "../token/ERC20.sol";
import "../crowdsale/Crowdsale.sol";
import "../vote/TapVoting.sol";
import "../lib/SafeMath.sol";
import "../lib/Param.sol";

contract ReservePool is Param {
    using SafeMath for uint256;

    ERC20 public token;
    Fund private fund;
    address public teamWallet;
    constructor(address _token, address _fund, address _teamWallet) public {
        //FIXIT: external???
        token = ERC20(_token);
        fund = Fund(_fund);
        teamWallet = _teamWallet;
    }

    modifier onlyFund(){
        require(msg.sender == address(fund));
        _;
    }

    event ReserveWithdrawTime(uint256 indexed time, uint256 indexed amount, address indexed team_wallet);

    function getBalance() public view returns(uint256) { return token.balanceOf(address(this)); }
    function getFund() public view returns(Fund) { return fund; }
    function getTokenAddress() public view returns(address) { return address(token); }

    function withdraw(uint256 token_amount) external onlyFund returns (bool) {
        require(token_amount <= getBalance(), "balance for reservePool is not enough");
        require(teamWallet != 0x0);
        token.transfer(teamWallet, token_amount);
        //tapvoting.party_list[account].isReceivedIncentive = true;
        //emit ReceiveIncentive(currentTapVotingNumber, msg.sender, getIncentiveAmountPerOne(msg.sender));
    }
}
