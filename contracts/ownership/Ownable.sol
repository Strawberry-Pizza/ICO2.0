pragma solidity ^0.4.23;


contract Ownable {
    enum DEV_LEVEL {NONE, DEV, OWNER}
    
    address public owner;
    address public fund_address;
    //address[] public developers; //contains owner
    mapping(address => DEV_LEVEL) developerLevel;

    bool public switch__fund_address = false;

    event CreateOwnership(address indexed owner_);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event EnrollDeveloper(address indexed owner_, address indexed dev_addr_);
    event DeleteDeveloper(address indexed owner_, address indexed dev_addr_);

    /* VIEW FUNCTION & CONSTRUCTOR */
    constructor(address _owner) public {
        require(_owner != 0x0);
        owner = _owner;
        emit CreateOwnership(owner);
        developerLevel[owner] = DEV_LEVEL.OWNER;
    }
    function isDeveloper(address addr) public constant returns(bool) {
        return uint(developerLevel[addr]) > uint(DEV_LEVEL.NONE);
    }

    /*MODIFIER*/
    modifier only(address addr) {
        require(addr != 0x0);
        require(msg.sender == addr, "Not given address");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyDevelopers() {
        require(isDeveloper(msg.sender), "Not Developers");
        _;
    }

    modifier notDevelopers() {
        require(!isDeveloper(msg.sender), "You are developer");
        _;
    }

    modifier onlyFund() {
        require(msg.sender == fund_address, "Not called by Fund");
        _;
    }

    /*FUNCTION*/
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != 0x0);
        require(isDeveloper(newOwner), "Not Developers");
        emit OwnershipTransferred(owner, newOwner);
        developerLevel[newOwner] = DEV_LEVEL.OWNER;
        developerLevel[owner] = DEV_LEVEL.NONE;
        owner = newOwner;
    }

    function enroll_developer(address dev_addr) public onlyOwner {
          require(dev_addr != 0x0);
          require(!isDeveloper(dev_addr), "It is developer");
          emit EnrollDeveloper(msg.sender, dev_addr);
          developerLevel[dev_addr] = DEV_LEVEL.DEV;
    }

    function delete_developer(address dev_addr) public onlyOwner {
          require(dev_addr != 0x0);
          require(dev_addr != owner, "Must not be self-destruct"); // must not be self-destruct
          require(isDeveloper(dev_addr), "Not Developers");
          emit DeleteDeveloper(msg.sender, dev_addr);
          developerLevel[dev_addr] = DEV_LEVEL.NONE;
    }
    function setFundAddress(address fund_addr) public onlyDevelopers {
        require(!switch__fund_address, "setFundAddress() already called once");
        switch__fund_address = true;
        fund_address = fund_addr;
        emit SetFund(fund_addr);
    }
}
