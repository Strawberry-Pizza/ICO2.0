/*
 * This contract is about manipulating funded ether.
 * After DAICO, funded ether follows this contract.
 */

pragma solidity ^0.4.21;

import "../token/BaseToken.sol";
import "../crowdsale/Crowdsale.sol";
import "../ownership/Ownable.sol";

contract Fund is Ownable, BaseToken, Crowdsale {

    // totalEther = [contract_account].balance

}

