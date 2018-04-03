/*
 * This contract is about manipulating funded ether.
 * After DAICO, funded ether follows this contract.
 */

pragma solidity ^0.4.18;

import "../token/DAICO_ERC20.sol";
import "../crowdsale/Crowdsale.sol";
import "../ownership/Ownable.sol";

contract Fund is Ownable, DAICO_ERC20, Crowdsale {

    // totalEther = [contract_account].balance

}

