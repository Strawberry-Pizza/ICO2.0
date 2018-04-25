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

    IERC20 public mToken;
    address public mCrowdsaleAddress;
    mapping(address => Tokens[]) public mWalletTokens;

    event TokensUnlocked(address _to, uint256 _value);
    
    /**
     * @dev LockedTokens constructor
     * @param _token ERC20 compatible token contract
     * @param _crowdsaleAddress Crowdsale contract address
     */
    constructor(IERC20 _token, address _crowdsaleAddress) public {
        mToken = _token;
        mCrowdsaleAddress = _crowdsaleAddress;
    }

    /**
     * @dev Functions locks tokens
     * @param _to Wallet address to transfer tokens after _lockEndTime
     * @param _amount Amount of tokens to lock
     * @param _lockEndTime End of lock period
     */
    function addTokens(address _to, uint256 _amount, uint256 _lockEndTime) internal {
        require(msg.sender == mCrowdsaleAddress);
        mWalletTokens[_to].push(Tokens({amount: _amount, lockEndTime: _lockEndTime, released: false}));
    }

    /**
     * @dev Called by owner of locked tokens to release them
     */
    function releaseTokens() public {
        require(mWalletTokens[msg.sender].length > 0);

        for(uint256 i = 0; i < mWalletTokens[msg.sender].length; i++) {
            if(!mWalletTokens[msg.sender][i].released && now >= mWalletTokens[msg.sender][i].lockEndTime) {
                mWalletTokens[msg.sender][i].released = true;
                mToken.transfer(msg.sender, mWalletTokens[msg.sender][i].amount);
                emit TokensUnlocked(msg.sender, mWalletTokens[msg.sender][i].amount);
            }
        }
    }
}