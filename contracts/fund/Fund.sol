/*
 * This contract is about manipulating funded ether.
 * After DAICO, funded ether follows this contract.
 */
pragma solidity ^0.4.23;

import "../fund/IncentivePool.sol";
import "../fund/ReservePool.sol";
import "../token/ERC20.sol";
import "../token/IERC20.sol";
import "../crowdsale/Crowdsale.sol";
import "../ownership/Ownable.sol";
import "../ownership/Members.sol";
import "../vote/VotingFactory.sol";
import "../vote/TapVoting.sol";
import "../vote/RefundVoting.sol";
import "../lib/SafeMath.sol";
import "../lib/Param.sol";

contract Fund is Ownable, Param {
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
    // totalEther = [contract_account].balance
    FUNDSTATE public state;
    ERC20 public token;
    address public teamWallet; // no restriction for withdrawing
    uint256 public tap;
    uint256 public retapVotingStartTime; // term that the new tap voting is able to restart
    uint256 public lastWithdrawTime;
    bool private switch__dividePoolAfterSale = false;
    bool private switch__lock_fund = false;

    Crowdsale public crowdsale;
    VotingFactory public votingFactory;
    TapVoting public tapVoting;
    RefundVoting public refundVoting;
    ReservePool public res_pool;
    IncentivePool public inc_pool;

    /* Modifiers */
    modifier period(FUNDSTATE _state) {
        require(state == _state, "Fund period is not matching");
        _;
    }

    modifier unlock {
        require(!switch__lock_fund, "fund has locked");
        _;
    }

    modifier lock {
        require(switch__lock_fund, "It is only executable when fund is locked");
        _;
    }

    /* Events */
    event CreateFund(address indexed token_address, address indexed team_wallet, address indexed fund_addr);
    event SetVotingFactoryAddress(address indexed voting_factory_addr, address indexed setter);
    event SetCrowdsaleAddress(address indexed voting_factory_addr, address indexed setter);
    event ChangeFundState(uint256 indexed time, FUNDSTATE indexed changed_state);
    event ChangeTap(uint256 indexed time, uint256 indexed changed_tap);
    event DividePoolAfterSale(address indexed fund_addr, address indexed inc_addr, address indexed res_addr);
    event WithdrawFromFund(uint256 indexed time, address indexed fund_addr, address indexed _teamwallet);
    event WithdrawFromIncentive(uint256 indexed time, address indexed inc_addr, address indexed _caller);
    event WithdrawFromReserve(uint256 indexed time, address indexed res_addr, address indexed _teamwallet);
    //add more

    /* Constructor */
    constructor(
        address _token,
        address _teamWallet,
        address _membersAddress
        ) public Ownable(_membersAddress) {
        require(_token != 0x0);
        require(_teamWallet != 0x0);
        require(_membersAddress != 0x0);
        state = FUNDSTATE.BEFORE_SALE;
        // setFundAddress(address(this)); //FIXIT: set fund address in Members.fundAddress
        token = ERC20(_token);
        teamWallet = _teamWallet;
        inc_pool = new IncentivePool(_token, address(this));
        res_pool = new ReservePool(_token, address(this), _teamWallet);
        tap = INITIAL_TAP;
        emit CreateFund(token, teamWallet, address(this));
    }

    /* View Function */
    function getVestingRate() view public returns(uint256) {
        uint256 term = now.sub(crowdsale.getStartTime()); // is the unit same?
        return term.div(DEV_VESTING_PERIOD);
    }
    function getState() view public returns(FUNDSTATE) { return state; }
    function getToken() view public returns(IERC20) { return token; }
    function getTeamWallet() view public returns(address) { return teamWallet; }
    function getTap() view public returns(uint256) { return tap; }
    function getVotingFactoryAddress() view public returns(address) { return address(votingFactory); }
    function getIncentiveAddress() view public returns(address) { return address(inc_pool); }
    function getReserveAddress() view public returns(address) { return address(res_pool); }
    function getWithdrawable() view public returns(uint256) { return tap*(now-lastWithdrawTime); }
    function getLocked() view public returns(bool) { return switch__lock_fund; }

    /* Set Function */
    function setVotingFactoryAddress(address _votingfacaddr) external onlyDevelopers unlock returns(bool) {
        require(_votingfacaddr != 0x0);
        votingFactory = VotingFactory(_votingfacaddr);
        emit SetVotingFactoryAddress(_votingfacaddr, msg.sender);
        return true;
    }
    function setCrowdsaleAddress(address _crowdsale) external onlyDevelopers unlock returns(bool) {
        require(_crowdsale != 0x0);
        crowdsale = Crowdsale(_crowdsale);
        emit SetCrowdsaleAddress(_crowdsale, msg.sender);
        return true;
    }

    /* Fallback Function */
    function () external payable {}

    /* State Function */
    function startSale() external period(FUNDSTATE.BEFORE_SALE) only(address(crowdsale)) {
        state = FUNDSTATE.CROWDSALE;
        emit ChangeFundState(now, state);
    }
    function finalizeSale() external period(FUNDSTATE.CROWDSALE) only(address(crowdsale)) {
        state = FUNDSTATE.WORKING;
        emit ChangeFundState(now, state);
    }
    function lockFund() external period(FUNDSTATE.WORKING) only(address(refundVoting)) unlock {
        state = FUNDSTATE.LOCKED;
        switch__lock_fund = true;
        emit ChangeFundState(now, state);
    }

    /* Tap Function */
    function increaseTap(uint256 change) external period(FUNDSTATE.WORKING) only(address(tapVoting)) unlock {
        tap = tap.add(change);
        emit ChangeTap(now, tap);
    }
    function decreaseTap(uint256 change) external period(FUNDSTATE.WORKING) only(address(tapVoting)) unlock {
        tap = tap.sub(change);
        emit ChangeTap(now, tap);
    }

    /* Withdraw Function */
    function dividePoolAfterSale(uint256[3] asset_percent) external period(FUNDSTATE.WORKING) only(address(crowdsale)) {
        //asset_percent = [public, incentive, reserve] = total 100
        require(!switch__dividePoolAfterSale);
        switch__dividePoolAfterSale = true; // this function is called only once.
        token.transfer(address(inc_pool), address(this).balance.mul(asset_percent[1]).div(100));
        token.transfer(address(res_pool), address(this).balance.mul(asset_percent[2]).div(100));
        emit DividePoolAfterSale(address(this), address(inc_pool), address(res_pool));
    }
    function withdrawFromFund() external period(FUNDSTATE.WORKING) only(address(tapVoting)) unlock payable returns(bool) {
        require(teamWallet != 0x0, "teamWallet has not determined.");
        require(getWithdrawable() != 0, "not enough withdrawable ETH.");
        uint256 withdraw_amount = getWithdrawable();
        teamWallet.transfer(withdraw_amount); //payable
        if(!_withdrawFromIncentive(withdraw_amount)) {revert();}
        emit WithdrawFromFund(now, address(this), teamWallet);
        return true;
    }
    function _withdrawFromIncentive(uint256 withdraw_amt) internal period(FUNDSTATE.WORKING) only(address(tapVoting)) unlock returns(bool) {
        require(address(inc_pool) != 0x0, "Incentive pool has not deployed.");

        if(!inc_pool.withdraw(withdraw_amt)) {revert();}
        emit WithdrawFromIncentive(now, address(inc_pool), msg.sender);
        return true;
    }
    function withdrawFromReserve(uint256 weiAmount) external onlyDevelopers period(FUNDSTATE.WORKING) unlock returns(bool) {
        require(address(res_pool) != 0x0, "Reserve pool has not deployed.");
        require(weiAmount <= address(res_pool).balance, "Not enough balance in reserve pool.");

        //TODO: not implemented
        uint256 tokenAmount = 100;
        if(!res_pool.withdraw(tokenAmount)) {revert();}
        emit WithdrawFromReserve(now, address(res_pool), teamWallet);
        return true;
    }
    /* Refund Function */
    function refund() external only(address(refundVoting)) period(FUNDSTATE.LOCKED) lock {
    //TODO: refund the whole ETH to token holders(by airdrop)
    //      except developers, advisors, pre-sale participants


    }
}

