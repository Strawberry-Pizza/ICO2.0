pragma solidity ^0.4.18;

import "../token/DAICO_ERC20.sol";
import "../lib/SafeMath.sol";
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
contract Crowdsale {
  using SafeMath for uint256;
  // The token being sold
  DAICO_ERC20 public token; //address
  uint256 public startTime;
  uint256 public endTime;
  address public beneficiary; // ether collecting address for crawdsale
  uint256 public fundingGoal;
  uint256 public currentAmount;

  // how many token units a buyer gets per wei
  uint256 public rate;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, uint256 wei_amount, uint256 token_amount, bool success);
  event StoreEtherToWallet(address indexed purchaser, address indexed wallet_address, uint256 wei_amount, uint256 token_amount, bool success);
  //event GoalReached(uint256 endtime, uint256 total_amount);

  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _beneficiary, address _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_beneficiary != address(0));
    require(_token != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    beneficiary = _beneficiary;
    token = DAICO_ERC20(_token);
  }

  modifier isSaleOpened() {
      require(now >= startTime && now <= endTime);
      require(currentAmount <= fundingGoal);
      _;
  }
  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address buyer) public payable isSaleOpened {
    require(buyer != address(0));
    require(msg.value + currentAmount <= fundingGoal);

    uint256 weiAmount = msg.value;
    // calculate token amount to be created
    uint256 token_amount = getTokenAmount(weiAmount); //token
    // update state
    currentAmount = SafeMath.safeAdd(currentAmount, weiAmount); //ether
    bool send_token_success = token.transfer(buyer, token_amount);
    TokenPurchase(buyer, weiAmount, token_amount, send_token_success);
    bool get_ether_success = forwardFunds(weiAmount);
    StoreEtherToWallet(msg.sender, beneficiary, weiAmount, token_amount, get_ether_success);
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return SafeMath.safeMul(weiAmount, rate);
  }
  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds(uint wei_amount) public payable returns (bool){
    require(msg.value == wei_amount);
    beneficiary.transfer(msg.value);
    return true;
  }
}
