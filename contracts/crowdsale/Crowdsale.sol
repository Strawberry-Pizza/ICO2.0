pragma solidity ^0.4.23;

import "../token/ERC20.sol";
import "../token/IERC20.sol";
import "../fund/Fund.sol";
import "../lib/SafeMath.sol";
import "../ownership/Ownable.sol";
/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Crowdsale is Ownable {
    /* Library and Typedefs */
    using SafeMath for uint256;
    /* Constants */
    uint public constant HARD_CAP = 37500 ether;
    uint public constant MIN_CONTRIB = 5000 ether;

    uint public constant PUB_TOKEN_PERC = 20;
    uint public constant PRIV_TOKEN_PERC = 20;
    uint public constant RESERVE_TOKEN_PERC = 20;
    uint public constant REWARD_TOKEN_PERC = 20;
    uint public constant DEV_TOKEN_PERC = 15;
    uint public constant ADV_TOKEN_PERC = 5;

    uint public constant ETHER_MIN_CONTRIB = 1 ether;
    uint public constant ETHER_MAX_CONTRIB = 300 ether;

    uint public constant SALE_START_TIME = 0;
    uint public constant SALE_END_TIME = 0;

    uint public constant DEFAULT_RATE = 50*10**5; // how many token units a buyer gets per wei

    /* Global Variables */
    IERC20 public token; //address
    Fund public fund; // ether bank, it should be Fund.sol's Contract address
    uint256 public currentAmount;
    uint8 public currentDiscountPerc = 20;
    /* Events */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 wei_amount, uint256 token_amount, bool success);
    event StoreEtherToWallet(address indexed purchaser, address indexed wallet_address, uint256 wei_amount, uint256 token_amount, bool success);
    event EtherChanges(address indexed purchaser, uint value); // send back ETH changes
    //event GoalReached(uint256 endtime, uint256 total_amount);
    /* Modifiers */
    modifier isSaleOpened() {
            require(now >= SALE_START_TIME && now <= SALE_END_TIME);
            require(currentAmount <= HARD_CAP);
            _;
    }
    /* Constructor */
    constructor(
        address _tokenAddress,
        address _fundAddress
        ) public Ownable(msg.sender) {
        require(_fundAddress != address(0));
        require(_tokenAddress != address(0));

        fund = Fund(_fundAddress);
        token = IERC20(_tokenAddress);
        fund.startSale(); //external function in Fund.sol
    }

    /* Fallback Function */
    function () external payable {
        buyTokens(msg.sender);
    }
    /* View Function */
    function getStartTime() view public returns(uint256) { return SALE_START_TIME; }
    function getEndTime() view public returns(uint256) { return SALE_END_TIME; }
    function getFundingGoal() view public returns(uint256) { return HARD_CAP; }
    function getCurrentAmount() view public returns(uint256) { return currentAmount; }
    /* Token Purchase Function */
    function buyTokens(address _beneficiary) public payable isSaleOpened {
        require(_beneficiary != address(0));

        uint256 weiAmount = msg.value;
        // calculate token amount to be created
        uint tokens;
        bool get_ether_success;
        bool send_token_success;
        if(!isOver(weiAmount)){
            tokens = getTokenAmount(weiAmount);
            send_token_success = token.transfer(_beneficiary, tokens);
            emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens, send_token_success);
        } else{
            uint ether1;
            uint ether2;
            if(currentDiscountPerc > 0){
                // When discount rate should be changed
                ether2 = address(this).balance.safeAdd(weiAmount).safeSub(HARD_CAP.safeMul(5 - currentDiscountPerc/5).safeDiv(8));
                ether1 = weiAmount.safeSub(ether2);
                tokens = getTokenAmount(ether1);
                send_token_success = token.transfer(_beneficiary, tokens);
                emit TokenPurchase(msg.sender, _beneficiary, ether1, tokens, send_token_success);

                currentDiscountPerc -= 5;
                uint additionalTokens = getTokenAmount(ether2);
                send_token_success = token.transfer(_beneficiary, additionalTokens);
                emit TokenPurchase(msg.sender, _beneficiary, ether2, additionalTokens, send_token_success);
                tokens = tokens.safeAdd(additionalTokens);
            } else if(currentDiscountPerc == 0){
                // When CrowdSale Ended
                ether2 = address(this).balance.safeAdd(weiAmount).safeSub(HARD_CAP);
                ether1 = weiAmount.safeSub(ether2);
                tokens = getTokenAmount(ether1);

                send_token_success = token.transfer(_beneficiary, tokens);
                emit TokenPurchase(msg.sender, _beneficiary, ether1, tokens, send_token_success);
                msg.sender.transfer(ether2);
                emit EtherChanges(msg.sender, ether2);
                get_ether_success = forwardFunds(ether1);
                emit StoreEtherToWallet(msg.sender, address(fund), ether1, tokens, get_ether_success);
                //finalize CrowdSale
                return;
            } else{
                revert("DiscountRate should be positive");
            }
        }
        get_ether_success = forwardFunds(weiAmount);
        emit StoreEtherToWallet(msg.sender, address(fund), weiAmount, tokens, get_ether_success);
    }
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > SALE_END_TIME;
    }
    // Override this method to have a way to add business logic to your crowdsale when buying
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.safeMul(getRate());
    }
    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds(uint wei_amount) public payable returns (bool){
        require(msg.value == wei_amount);
        address(fund).transfer(msg.value);
        return true;
    }
    function _dividePool() internal onlyOwner {
        fund.dividePoolAfterSale();
    }
    function finalizeFunds() public onlyOwner{
        require(hasEnded());
        fund.finalizeSale();
        _dividePool();
        //close sale
        //give initial fund
        //Refund vote activate
        //set tapVoting available
        //start lock counting
    }

    // get current rate including the dicount percentage
    function getRate() public view returns (uint){
        uint rate = DEFAULT_RATE;
        if(currentDiscountPerc == 0){
            return rate;
        } else{
            return rate.safeMul(100).safeDiv(100 - currentDiscountPerc);
        }
    }

    // function which checks the amount would be over next cap
    function isOver(uint _weiAmount) public view returns(bool){
        if(currentDiscountPerc == 0){
            if(address(this).balance.safeAdd(_weiAmount) > HARD_CAP){
                return true;
            } else{
                return false;
            }
        }
        if(address(this).balance.safeAdd(_weiAmount) > HARD_CAP.safeMul(5 - currentDiscountPerc/5).safeDiv(8)){
            return true;
        } else{
            return false;
        }
    }
}
