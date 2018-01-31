pragma solidity 0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract MenuToken is StandardToken, Ownable {
    
    string public constant symbol = "MENU";
    string public constant name = "MenuBuzz";
    uint8 public constant decimals = 10;

  function MenuToken()
    public
    {
        totalSupply_ = 700000000 * 10**10;
        balances[msg.sender] = totalSupply_;
        assert(balances[owner] == totalSupply_);                
    }

}





