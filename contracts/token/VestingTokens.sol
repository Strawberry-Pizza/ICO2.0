pragma solidity ^0.4.21;

import "./LockedTokens.sol";

contract VestingTokens is LockedTokens {

    uint public constant DEV_VEST_PERIOD_1 = 12 weeks;
    uint public constant DEV_VEST_PERIOD_2 = 1 years;
    uint public constant DEV_VEST_PERC_1 = 30;
    uint public constant DEV_VEST_PERC_2 = 70;

    uint public constant ADV_VEST_PERIOD_1 = 12 weeks;
    uint public constant ADV_VEST_PERIOD_2 = 1 years;
    uint public constant ADV_VEST_PERC_1 = 30;
    uint public constant ADV_VEST_PERC_2 = 70;

    uint public constant PRIV_VEST_PERIOD_1 = 12 weeks;
    uint public constant PRIV_VEST_PERIOD_2 = 1 years;
    uint public constant PRIV_VEST_PERC_1 = 30;
    uint public constant PRIV_VEST_PERC_2 = 70;

    enum LOCK_TYPE {DEV, ADV, PRIV}

    function VestingTokens(IERC20 _token, address _crowdsaleAddress) public {
        token = _token;
        crowdsaleAddress = _crowdsaleAddress;
    }

    function lockup(address _to, uint256 _amount, LOCK_TYPE _type) external {
        if(_type == LOCK_TYPE.DEV){
            super.addTokens(_to, _amount.safeMul(DEV_VEST_PERC_1).safeDiv(100), DEV_VEST_PERIOD_1);
            super.addTokens(_to, _amount.safeMul(DEV_VEST_PERC_2).safeDiv(100), DEV_VEST_PERIOD_2);
        } else if(_type == LOCK_TYPE.ADV){
            super.addTokens(_to, _amount.safeMul(ADV_VEST_PERC_1).safeDiv(100), ADV_VEST_PERIOD_1);
            super.addTokens(_to, _amount.safeMul(ADV_VEST_PERC_2).safeDiv(100), ADV_VEST_PERIOD_2);
        } else if(_type == LOCK_TYPE.PRIV){
            super.addTokens(_to, _amount.safeMul(PRIV_VEST_PERC_1).safeDiv(100), PRIV_VEST_PERIOD_1);
            super.addTokens(_to, _amount.safeMul(PRIV_VEST_PERC_2).safeDiv(100), PRIV_VEST_PERIOD_2);
        } else{
            revert();
        }
    }

}