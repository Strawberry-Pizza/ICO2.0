/*
 * This contract is about manipulating funded ether.
 * After DAICO, funded ether follows this contract.
 */

pragma solidity ^0.4.21;

import "../token/ERC20.sol";
import "../token/IERC20.sol";
import "../crowdsale/Crowdsale.sol";
import "../ownership/Ownable.sol";
import "../lib/SafeMath.sol";

contract Fund is Ownable, IERC20, Crowdsale {
    using SafeMath for uint256;
    enum FUNDSTATE {
        BEFORE_SALE,
        CROWDSALE,
        WORKING,
        LOCKED,
        COLLAPSED
    }

    /*Global variables*/
    // totalEther = [contract_account].balance
    FUNDSTATE public state;
    IERC20 public token;
    address public teamWallet; // no restriction for withdrawing
    uint256 public constant INITIAL_TAP = 0.01 ether; //(0.01 ether/sec)
    uint256 public tap;
    address public votingFactoryAddress;
    IncentivePool inc_pool;

    /*Modifiers*/
    modifier period(FUNDSTATE _state) {
        require(state == _state);
        _;
    }

    /*Events*/
    event CreateFund(address indexed token_address, address indexed team_wallet, address creator);
    //add more

    /*Constructor*/
    function Fund(address _token, address _teamWallet) public onlyDevelopers {
        token = IERC20(_token);
        teamWallet = _teamWallet;
        state = FUNDSTATE.BEFORE_SALE;
        inc_pool = new IncentivePool();
        emit CreateFund(token, teamWallet, msg.sender);
    }

    /*view function*/
    function getState() view public returns(FUNDSTATE) { return state; }

    /*set function*/
    function setVotingFactoryAddress(address _votingfacaddr) external onlyDevelopers{ 
        require(_votingfacaddr != 0x0);
        votingFactoryAddress = _votingfacaddr; 
    }
    
    /*fallback function*/
    function () external payable {}

    /*state function*/
    function startSale() external period(FUNDSTATE.BEFORE_SALE) {}
    function finalizeSale() external period(FUNDSTATE.CROWDSALE) {}
    function dividePoolAfterSale() external period(FUNDSTATE.WORKING) payable {
    //TODO: divide ETH into incentive pool(1%) and others.
    }
    
    /*tap function*/
    function increaseTap(uint256 change) external period(FUNDSTATE.WORKING) {}
    function decreaseTap(uint256 change) external period(FUNDSTATE.WORKING) {}

    /*withdraw function*/
    function withdrawFromFund() external onlyDevelopers period(FUNDSTATE.WORKING) payable {}

    /*lock function*/
    function lockFund() external period(FUNDSTATE.WORKING) {}

    /*refund function*/
    function refund() external period(FUNDSTATE.LOCKED) {}
}

