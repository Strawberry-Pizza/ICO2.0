pragma solidity ^0.4.23;

contract Members {
    enum DEV_LEVEL {NONE, DEV, OWNER}

    address owner_;
    mapping(address => DEV_LEVEL) developerLevel;

    event CreateOwnership(address indexed _owner);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event EnrollDeveloper(address indexed _owner, address indexed _devAddress);
    event DeleteDeveloper(address indexed _owner, address indexed _devAddress);

    modifier onlyOwner() {
        require(msg.sender == owner_, "Not Owner");
        _;
    }

    constructor() public {
        owner_ = msg.sender;
        emit CreateOwnership(owner_);
        developerLevel[owner_] = DEV_LEVEL.OWNER;
    }

    function owner() external view returns(address){
        return owner_;
    }

    function isDeveloper(address addr) public view returns(bool) {
        return uint(developerLevel[addr]) > uint(DEV_LEVEL.NONE);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != 0x0);
        require(isDeveloper(newOwner), "Not Developers");
        emit OwnershipTransferred(owner_, newOwner);
        developerLevel[newOwner] = DEV_LEVEL.OWNER;
        developerLevel[owner_] = DEV_LEVEL.NONE;
        owner_ = newOwner;
    }

    function enroll_developer(address dev_addr) public onlyOwner {
        require(dev_addr != 0x0);
        require(!isDeveloper(dev_addr), "It is developer");
        emit EnrollDeveloper(msg.sender, dev_addr);
        developerLevel[dev_addr] = DEV_LEVEL.DEV;
    }

    function delete_developer(address dev_addr) public onlyOwner {
        require(dev_addr != 0x0);
        require(dev_addr != owner_, "Must not be self-destruct"); // must not be self-destruct
        require(isDeveloper(dev_addr), "Not Developers");
        emit DeleteDeveloper(msg.sender, dev_addr);
        developerLevel[dev_addr] = DEV_LEVEL.NONE;
    }
}
