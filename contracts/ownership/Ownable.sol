pragma solidity ^0.4.23;

import "./Members.sol";


contract Ownable {
    Members members;

    /* CONSTRUCTOR */
    constructor(address _membersAddress) public {
        require(_membersAddress != 0x0);
        members = Members(_membersAddress);
    }

    /*MODIFIER*/
    modifier only(address _address){
        require(msg.sender == _address);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == members.owner(), "Not Owner");
        _;
    }

    modifier onlyDevelopers() {
        require(members.isDeveloper(msg.sender), "Not Developers");
        _;
    }

    modifier notDevelopers() {
        require(!members.isDeveloper(msg.sender), "You are developer");
        _;
    }
}
