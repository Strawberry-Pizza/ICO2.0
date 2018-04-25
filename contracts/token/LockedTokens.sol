pragma solidity ^0.4.23;

import "../lib/SafeMath.sol";
import "./IERC20.sol";
import "../ownership/Ownable.sol";


/**
 * @title LockedTokens
 * @dev Lock tokens for certain period of time
 */
contract LockedTokens {
    using SafeMath for uint256;
    struct Tokens {
        uint256 amount;
        uint256 lockEndTime;
        bool released;
    }

    event TokensUnlocked(address _to, uint256 _value);

    IERC20 public token;
    address public crowdsaleAddress;
    mapping(address => Tokens[]) public walletTokens;

    /**
     * @dev LockedTokens constructor
     * @param _token ERC20 compatible token contract
     * @param _crowdsaleAddress Crowdsale contract address
     */
    constructor(IERC20 _token, address _crowdsaleAddress) public {
        token = _token;
        crowdsaleAddress = _crowdsaleAddress;
    }

    /**
     * @dev Functions locks tokens
     * @param _to Wallet address to transfer tokens after _lockEndTime
     * @param _amount Amount of tokens to lock
     * @param _lockEndTime End of lock period
     */
    function addTokens(address _to, uint256 _amount, uint256 _lockEndTime) internal {
        require(msg.sender == crowdsaleAddress);
        walletTokens[_to].push(Tokens({amount: _amount, lockEndTime: _lockEndTime, released: false}));
    }

    /**
     * @dev Called by owner of locked tokens to release them
     */
    function releaseTokens() public {
        require(walletTokens[msg.sender].length > 0);

        for(uint256 i = 0; i < walletTokens[msg.sender].length; i++) {
            if(!walletTokens[msg.sender][i].released && now >= walletTokens[msg.sender][i].lockEndTime) {
                walletTokens[msg.sender][i].released = true;
                token.transfer(msg.sender, walletTokens[msg.sender][i].amount);
                emit TokensUnlocked(msg.sender, walletTokens[msg.sender][i].amount);
            }
        }
    }
}