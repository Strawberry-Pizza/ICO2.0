pragma solidity ^0.4.18;

import "../token/DAICO_ERC20.sol";
import "../ownership/Ownable.sol";
import "../lib/SafeMath.sol";

contract Refund is Ownable {
    using SafeMath for uint256;

    DAICO_ERC20 public token;
    /* CONSTRUCTOR */
    function Refund(address _token) public onlyDevelopers {
        token = DAICO_ERC20(_token);
    }
    /* EVENTS */
    event Refund(address indexed account, uint256 refunded_wei_amount, uint256 token_amount, uint256 rate, bool success);
    /* VIEW FUNCTION */
    function estimateRefundETH(uint256 token_amount, address account) public view returns(uint256) {
        uint256 _rate = SafeMath.safeDiv(token_amount,token.getTotalSupply());
        uint256 _refundedWeiAmount = SafeMath.safeMul(_rate, token.getBeneficiaryWeiAmount());
        return _refundedWeiAmount;
    }
    /* FUNCTION */
    function refund(uint256 token_amount, address account) public returns(bool) {
        require(token_amount <= token.getBalanceOf(account));

        uint256 _rate = SafeMath.safeDiv(token_amount,token.getTotalSupply());
        uint256 _refundedWeiAmount = SafeMath.safeMul(_rate, token.getBeneficiaryWeiAmount());
        //get refunds from contract account
        if(!msg.sender.send(_refundedWeiAmount)) {
            Refund(account, _refundedWeiAmount, token_amount, _rate, false);
            throw;
        }
        Refund(account, _refundedWeiAmount, token_amount, _rate, true);
        return true;
    }
}




