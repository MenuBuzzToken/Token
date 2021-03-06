pragma solidity 0.4.19;

import './StandardToken.sol';
import './Ownable.sol';

contract MenuToken is StandardToken, Ownable {
    
    string public constant symbol = "MENU";
    string public constant name = "MenuBuzz";
    uint256 public constant decimals = 10;

  function MenuToken()
    public
    {
        totalSupply_ = 800000000 * 10**10;
        balances[msg.sender] = totalSupply_;
        assert(balances[owner] == totalSupply_);                
    }

}





