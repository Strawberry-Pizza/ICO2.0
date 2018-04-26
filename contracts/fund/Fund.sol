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
import "zeppelin-solidity/contracts/math/SafeMath.sol";

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
    bool private isDividePoolAfterSale = false;

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
    event CreateFund(address indexed token_address, address indexed team_wallet, address indexed fund_addr);
    event SetVotingFactoryAddress(address indexed voting_factory_addr, address indexed setter);
    event SetCrowdsaleAddress(address indexed voting_factory_addr, address indexed setter);
    event ChangeFundState(uint256 indexed time, FUNDSTATE indexed changed_state);
    event ChangeTap(uint256 indexed time, uint256 indexed changed_tap);
    event DividePoolAfterSale(address indexed fund_addr, address indexed inc_addr, address indexed res_addr);
    event WithDrawFromFund(uint256 indexed time, address indexed fund_addr, address indexed _teamwallet);
    event WithDrawFromIncentive(uint256 indexed time, address indexed inc_addr, address indexed _caller);
    event WithDrawFromReserve(uint256 indexed time, address indexed res_addr, address indexed _teamwallet);
    //add more

    /* Constructor */
    constructor(address _token, address _teamWallet) public onlyDevelopers {
        state = FUNDSTATE.BEFORE_SALE;
        setFundAddress(address(this)); // set fund address in Ownable.fundAddress
        token = IERC20(_token);
        teamWallet = _teamWallet;
        inc_pool = new IncentivePool();
        res_pool = new ReservePool();
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

    /* Set Function */
    function setVotingFactoryAddress(address _votingfacaddr) external onlyDevelopers returns(bool) {
        require(_votingfacaddr != 0x0);
        votingFactoryAddress = _votingfacaddr;
        emit SetVotingFactoryAddress(_votingfacaddr, msg.sender);
        return true;
    }
    function setCrowdsaleAddress(address _crowdsale) external onlyDevelopers returns(bool) {
        require(_crowdsale != 0x0);
        crowdsale = _crowdsale;
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
    function lockFund() external period(FUNDSTATE.WORKING) only(address(crowdsale)) {
        state = FUNDSTATE.LOCKED;
        emit ChangeFundState(now, state);
    }

    /* Tap Function */
    function increaseTap(uint256 change) external period(FUNDSTATE.WORKING) only(address(tapVoting)) {
        tap = tap.add(change);
        emit ChangeTap(now, tap)
    }
    function decreaseTap(uint256 change) external period(FUNDSTATE.WORKING) only(address(tapVoting)) {
        tap = tap.sub(change);
        emit ChangeTap(now, tap);
    }

    /* Withdraw Function */
    function dividePoolAfterSale(uint256[3] asset_percent) external period(FUNDSTATE.WORKING) only(address(crowdsale)) payable {
        //asset_percent = [public, incentive, reserve] = total 100
        require(!isDividePoolAfterSale);
        isDividePoolAfterSale = true; // this function is called only once.
        address(inc_pool).transfer(this.balance.mul(asset_percent[1]).div(100));
        address(res_pool).transfer(this.balance.mul(asset_percent[2]).div(100));
        emit DividePoolAfterSale(address(this), address(inc_pool), address(res_pool));
    }
    function withdrawFromFund() external period(FUNDSTATE.WORKING) only(address(tapVoting)) payable returns(bool) {
        require(teamWallet != 0x0, "teamWallet has not determined.");
        require(getWithdrawable() != 0, "not enough withdrawable ETH.");

        if(!teamWallet.send(getWithdrawable())) { revert(); }
        if(!withdrawFromIncentive()) { revert(); }
        emit withdrawFromFund(now, address(this), teamWallet);
        return true;
    }
    function withdrawFromIncentive() internal period(FUNDSTATE.WORKING) only(address(tapVoting)) payable returns(bool) {
        require(address(inc_pool) != 0x0, "Incentive pool has not deployed.");
        
        if(!inc_pool.withdraw()) { revert(); }
        emit withdrawFromIncentive(now, address(inc_pool), msg.sender);
        return true;
    }
    function withdrawFromReserve(uint256 weiAmount) external onlyDevelopers period(FUNDSTATE.WORKING) payable returns(bool) {
        require(address(res_pool) != 0x0, "Reserve pool has not deployed.");
        require(weiAmount <= address(res_pool).balance, "Not enough balance in reserve pool.");
        
        //TODO: not implemented
        if(!res_pool.withdraw()) { revert(); }
        emit withdrawFromReserve(now, address(res_pool), teamWallet);
        return true;
    }
    /* Refund Function */
    function refund() external period(FUNDSTATE.LOCKED) {}
}

