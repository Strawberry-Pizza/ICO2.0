/*
 * This contract is about manipulating funded ether.
 * After DAICO, funded ether follows this contract.
 */
pragma solidity ^0.4.23;

import "../fund/IncentivePool.sol";
import "../token/ERC20.sol";
import "../token/IERC20.sol";
import "../crowdsale/Crowdsale.sol";
import "../ownership/Ownable.sol";
import "../lib/SafeMath.sol";

contract Fund is Ownable {
    /* Library and Typedefs */
    using SafeMath for uint256;
    enum FUNDSTATE {
        BEFORE_SALE,
        CROWDSALE,
        WORKING,
        LOCKED,
        COLLAPSED
    }

    /* Global Variables */
    uint256 public constant INITIAL_TAP = 0.01 ether; //(0.01 ether/sec)
    uint256 public constant DEV_VESTING_PERIOD = 1 years;
    // totalEther = [contract_account].balance
    FUNDSTATE public state;
    ERC20 public token;
    address public teamWallet; // no restriction for withdrawing
    uint256 public tap;
    uint256 public retapVotingStartTime; // term that the new tap voting is able to restart
    uint256 public lastWithdrawTime;

    Crowdsale public crowdsale;
    VotingFactory public votingFactory;
    ReservePool public res_pool;
    IncentivePool public inc_pool;

    /* Modifiers */
    modifier period(FUNDSTATE _state) {
        require(state == _state, "Different Period");
        _;
    }

    /* Events */
    event CreateFund(address indexed token_address, address indexed team_wallet, address creator);
    //add more

    /* Constructor */
    constructor(address _token, address _teamWallet, address _crowdsale) public onlyDevelopers {
        state = FUNDSTATE.BEFORE_SALE;
        token = IERC20(_token);
        teamWallet = _teamWallet;
        crowdsale = Crowdsale(_crowdsale);
        inc_pool = new IncentivePool();
        res_pool = new ReservePool();
        tap = INITIAL_TAP;
        emit CreateFund(token, teamWallet, msg.sender);
    }

    /* View Function */
    function getVestingRate() view public returns(uint256) {
        uint256 term = SafeMath.safeSub(now, crowdsale.getStartTime()); // is the unit same?
        return SafeMath.safeDiv(term, DEV_VESTING_PERIOD);
    }
    function getState() view public returns(FUNDSTATE) { return state; }
    function getToken() view public returns(IERC20) { return token; }
    function getTeamWallet() view public returns(address) { return teamWallet; }
    function getTap() view public returns(uint256) { return tap; }
    function getVotingFactoryAddress() view public returns(address) { return address(votingFactory); }
    function getIncentiveAddress() view public returns(address) { return address(inc_pool); }
    function getReserveAddress() view public returns(address) { return address(res_pool); }
    function getWithdrawable() view public returns(uint256) { return tap*(now-lastWithdrawTime); }

    /* Set Function */
    function setVotingFactoryAddress(address _votingfacaddr) external onlyDevelopers{
        require(_votingfacaddr != 0x0);
        votingFactoryAddress = _votingfacaddr;
    }

    /* Fallback Function */
    function () external payable {}

    /* State Function */
    function startSale() external period(FUNDSTATE.BEFORE_SALE) {}
    function finalizeSale() external period(FUNDSTATE.CROWDSALE) {}
    function lockFund() external period(FUNDSTATE.WORKING) {}

    /* Tap Function */
    function increaseTap(uint256 change) external period(FUNDSTATE.WORKING) {
        tap.safeAdd(change);
    }
    function decreaseTap(uint256 change) external period(FUNDSTATE.WORKING) {
        tap.safeSub(change);
    }

    /* Withdraw Function */
    function dividePoolAfterSale() external period(FUNDSTATE.WORKING) payable {
    //TODO: divide ETH into incentive pool(1%) and others.
    }
    function withdrawFromFund() external onlyDevelopers period(FUNDSTATE.WORKING) payable returns(bool) {
        require(teamWallet != 0x0, "teamWallet has not determined.");
        if(!teamWallet.send(address(this))) { revert(); }
        if(!withdrawFromIncentive()) { revert(); }
        return true;
    }
    function withdrawFromIncentive() external onlyDevelopers period(FUNDSTATE.WORKING) payable returns(bool) {
        require(address(inc_pool) != 0x0, "Incentive pool has not deployed.");
        if(!inc_pool.withdraw()) { revert(); }
        return true;
    }
    function withdrawFromReserve(uint256 weiAmount) external onlyDevelopers period(FUNDSTATE.WORKING) payable returns(bool) {
        require(address(res_pool) != 0x0, "Reserve pool has not deployed.");
        require(weiAmount <= res_pool.address, "Not enough balance in reserve pool.");
        if(!res_pool.withdraw()) { revert(); }
        return true;
    }


    /* Refund Function */
    function refund() external period(FUNDSTATE.LOCKED) {}
}

