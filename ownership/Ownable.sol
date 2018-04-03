pragma solidity ^0.4.18;


contract Ownable {
  address public owner;
  //address[] public developers; //contains owner
  enum DEV_LEVEL {NONE, DEV, OWNER};
  mapping(address => DEV_LEVEL) developerLevel;


  event CreateOwnership(address indexed owner_);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event EnrollDeveloper(address indexed owner_, address indexed dev_addr_);
  event DeleteDeveloper(address indexed owner_, address indexed dev_addr_);

  /* VIEW FUNCTION & CONSTRUCTOR */
  function Ownable() public {
    require(msg.sender != 0x0);
    CreateOwnership(owner);
    owner = msg.sender;
    developerLevel[owner] = DEV_LEVEL.OWNER;
  }
  function isDeveloper(address addr) public constant returns(bool) {
      return uint(developerLevel[addr]) > uint(DEV_LEVEL.NONE);
  }

  /*MODIFIER*/
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyDevelopers() {
    require(isDeveloper(msg.sender));
    _;
  }

  modifier notDevelopers() {
    require(!isDeveloper(msg.sender));
    _;
  }

  /*FUNCTION*/
  function transferOwnership(address newOwner) public onlyOwner {
    require(isDeveloper(newOwner));
    OwnershipTransferred(owner, newOwner);
    developerLevel[newOwner] = DEV_LEVEL.OWNER;
    developerLevel[owner] = DEV_LEVEL.NONE;
    owner = newOwner;
  }

  function enroll_developer(address dev_addr) public onlyOwner {
      require(dev_addr != 0x0);
      require(!isDeveloper(dev_addr));
      EnrollDeveloper(msg.sender, dev_addr);
      developerLevel[dev_addr] = DEV_LEVEL.DEV;
  }

  function delete_developer(address dev_addr) public onlyOwner {
      require(dev_addr != 0x0);
      require(dev_addr != owner); // must not be self-destruct
      require(isDeveloper(dev_addr));
      DeleteDeveloper(msg.sender, dev_addr);
      developerLevel[dev_addr] = DEV_LEVEL.NONE;
  }

}
