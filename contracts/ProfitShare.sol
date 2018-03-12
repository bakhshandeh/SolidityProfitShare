pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol';
import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract ProfitShare is StandardToken{
    using SafeMath for uint256;

    string public name = "ProfitShare Token";
    string public symbol = "PShare";
    uint256 public decimals = 18;

    // 267M
    uint256 public totalSupply = 422370000 * (uint256(10) ** decimals);
    uint256 public totalRaised; // total ether raised (in wei)

    uint256 public totalShareable; // total shareable ethers (in wei)

    // 1 ETH = 87245 PShare
    uint256 public coinPerETH = 87245;

    /**
     * List of all users
     */
    address[] public allUsers;

    // whitelisted users
    mapping(address => bool) public whiteList;

    mapping(address => bool) public blackList;
    address[] public allBlacklist;

    /**
     * Address which will receive raised funds 
     * and owns the total supply of tokens
     */
    address public fundsWallet;


    function ProfitShare() {
        fundsWallet = 0x8c7704eA2d934692B21419Bf2a5AC6165a45CE98;
        balances[fundsWallet] = totalSupply;

        //blackList[fundsWallet] = true;
        //allBlacklist[++allBlacklist.length] = fundsWallet;

        // launch coins and send them to fundsWallet
        Transfer(0x0, fundsWallet, totalSupply);
    }

    /**
     * This function will be called when
     * users send ETH to buy the tokens.
     * 
     * We will calculate the Pshare amount and send to their wallets
     */
    function() isIcoOpen checkMin isInWhitelist payable{
        if(msg.sender == fundsWallet){
            totalShareable = msg.value;
            return shareProfits();
        }
        totalRaised = totalRaised.add(msg.value);

        uint256 tokenAmount = calculateTokenAmount(msg.value);

        balances[fundsWallet] = balances[fundsWallet].sub(tokenAmount);

        // If its the first time that the user is paying 
        if(!contains(allUsers, msg.sender) && msg.sender != fundsWallet){
            allUsers[allUsers.length++] = msg.sender;
        }

        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
 
        Transfer(fundsWallet, msg.sender, tokenAmount);

        // immediately transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
    }

    /**
     * Shares profit between all coin holders
     */    
    function shareProfits(){
        uint256 totalActiveCoins = calculateTotalActiveCoins();
        for (uint i = 0; i < allUsers.length; i++) {
            if(balances[allUsers[i]] != 0){
                uint256 shareMount = balances[allUsers[i]].mul(totalShareable).div(totalActiveCoins);
                allUsers[i].transfer(shareMount);
            }
        }
    }

    /**
     * Calculates total number of active coins
     */
    function calculateTotalActiveCoins() constant returns(uint256){
        uint256 total = totalSupply.sub(balances[fundsWallet]);
        for (uint i = 0; i < allBlacklist.length; i++) {
            if(blackList[allBlacklist[i]]){
                total = total.sub(balances[allBlacklist[i]]);
            }
        }
        return total;
    }

    /**
     * Returns allUsers elements
     */
    function getUser(uint256 index) constant returns(address){
        return allUsers[index];
    }

    /**
     * Calculates the total PShare amount
     */
    function calculateTokenAmount(uint256 weiAmount) constant returns(uint256) {
        uint256 tokenAmount = weiAmount.mul(coinPerETH);
        return tokenAmount;
    }

    /**
     * Transfers tokens to a new wallet
     * 
     * @param   _to -- destination address
     * @param   _value -- wie amount
     */
    function transfer(address _to, uint _value) returns (bool) {
        if(!contains(allUsers, _to) && _to != fundsWallet){
            allUsers[allUsers.length++] = _to;
        }
        return super.transfer(_to, _value);
    }

    /**
     * Transfers tokens from one wallet to an another wallet
     * 
     * @param   _from -- source address
     * @param   _to -- destination address
     * @param   _value -- wie amount
     */
    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if(!contains(allUsers, _to) && _to != fundsWallet){
            allUsers[allUsers.length++] = _to;
        }
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * Throws an exception and reject the transaction when we don't have enough 
     * tokens.
     * When all tokens are sold out, the contract can't accept new incoming ethers
     * and need to reject transactions
     */
    modifier isIcoOpen() {
        require(msg.sender == fundsWallet ||
            totalRaised.mul(coinPerETH) <= totalSupply);
        _;
    }

    /**
     * Investors can buy at least 1 Pshare.
     * Smaller amounts will be rejected.
     */
    modifier checkMin(){
        require(msg.value.mul(coinPerETH) >= (uint256(10) ** decimals));
        _;
    }

    /**
     * Checks to make sure that the sender is admin.
     * Will throw an exception and reject the transaction if the sender is not admin.
     * We need this function for some restricted functions.
     */
    modifier isOwner(){
        require(msg.sender == fundsWallet);
        _;
    }

    /**
     * Checks to make sure that the sender is in WhiteList
     */
    modifier isInWhitelist(){
        require(whiteList[msg.sender] || msg.sender == fundsWallet);
        _;
    }


    /**
     * Check if an address is in the list or not
     * Returns true if exists else false
     */
    function contains(address[] storage list, address addr) 
            internal constant returns (bool) {
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * Allows the admin to add user to whitelist
     */
    function adminAddWhiteList(address _address) isOwner returns(bool){
        whiteList[_address] = true;
        return true;
    }

    /**
     * Allows the admin to remove a user from whitelist
     */
    function adminRemoveWhiteList(address _address) isOwner returns(bool){
        whiteList[_address] = false;
        return true;
    }

    /**
     * Allows the admin to update the status of an address on blackList
     */
    function adminUpdateBlackList(address _address, bool _val) isOwner returns(bool){
        blackList[_address] = _val;
        if(!contains(allBlacklist, _address)){
            allBlacklist[allBlacklist.length++] = _address;
        }
        return true;
    }
}
