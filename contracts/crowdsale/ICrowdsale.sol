pragma solidity ^0.4.23;

import "../token/VestingTokens.sol";

contract ICrowdsale{
    /* Funcitons */
    /* View Functions */
    function getStartTime() view public returns(uint256);
    function getEndTime() view public returns(uint256);
    
    function getFundingGoal() view public returns(uint256);
    function getCurrentSate() view external returns(string);
    function getRate() public view returns (uint);
    function getNextCap() public view returns(uint);
    
    function getCurrentAmount() view public returns(uint256);
    function getLockedAmount(VestingTokens.LOCK_TYPE _type) view public returns(uint256);
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256);

    function isOver(uint _weiAmount) public view returns(bool);
    function isLockFilled() public view returns(bool);

    /* Change CrowdSale State, call only once */
    function activateSale() public;
    function _finishSale() private;
    function finalizeSale() public;

    /* Token Purchase Functions */
    function buyTokens(address _beneficiary) public payable;
    
    /* Set Functions */
    function setVestingTokens(address _vestingTokensAddress) public;

    function setToDevelopers(address _address, uint _amount) public;
    function setToAdvisors(address _address, uint _amount) public;
    function setToPrivateSale(address _address, uint _amount) public;
    //function addToUserContributed

    /* Finalizing Functions */
    function _lockup() private;
    function _forwardFunds() private returns (bool);
    function _dividePool() internal;
}