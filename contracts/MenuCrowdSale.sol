pragma solidity 0.4.18;

import './MenuToken.sol';
import './MenuTeamWallet.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract MenuCrowdSale is Ownable{
  using SafeMath for uint256;

  uint256 constant internal MIN_CONTRIBUTION = 1 ether;
  uint256 constant internal TOKEN_DECIMALS = 10**10;
  uint256 constant internal ETH_DECIMALS = 10**18;
  uint256 constant public PRICE = 20000; //tokens per ether
  uint8 constant internal TIERS = 4;
  uint256 public icoEndTime;
  uint256 public weiRaised;
  uint256 public ethPrice;
  address public holdings;
  address public owner;
  uint256 public timer;
  uint256 public cap;
  uint8 private tier;
  bool private paused;

  //The MenuBuzz token and team wallet contracts
  MenuToken public menuToken;
  MenuTeamWallet public menuTeamWallet; 
  
  enum WhitelistStatus{
    NC, Denied, OneEth, TenEth, NoLimitEth //change to what lawyer says
  }

  struct Purchase {
    uint256 bonusTokenAmount;//will be 10 percent of the qtyTokens amount
    uint256 bonusPrcntg;
    uint8 tierPurchased;
  }

  struct Participant{
    uint256 contrAmount;
    uint256 qtyTokens;
    uint256 remainingWei;
    WhitelistStatus wLStatus;
    Purchase[] purchases;
    uint8 bonusPaidCounter;
  }

  ///@notice risk createing open ended array will be trying during testing to limit the amount
  ///gas by limiting the array size to say 10
  //mapping(address => Purchase[]) public purchases;
  mapping(address => Participant) public participants;

  struct SaleTier {      
    uint256 tokensToBeSold;  //amount of tokens to be sold in this SaleTier
    uint256 tokensSold;      //amount of tokens sold in each SaleTier 
    uint256 tokensPerEth;
    uint256 bonusAmount;    
  }
   
  mapping(uint8 => SaleTier) saleTier;

  event LogTokensClaimed(address _owner, address _msgsender, uint256 _qtyOfTokensRequested);
  event LogTokensReserved(address _buyer, uint256 _amount);
  event LogOwnerWithdrawal(address _owner, uint256 _amount);
  event LogRefundWei(address _participant, uint256 _amount);
  event LogBonusTokensSent(address _participant, uint256 _amountTkns); 
 
  modifier isValidPayload() {
    require(msg.data.length == 0 || msg.data.length == 4); // double check this one
    _;
  }

  modifier icoIsActive() {
    require(weiRaised < cap && now < icoEndTime && calculateRemainingTokens() > 0);
    _;
  }

  modifier icoHasEnded() {
    require(weiRaised >= cap || now > icoEndTime || calculateRemainingTokens() == 0);
    _;
  }

  modifier activeContract(){
    require(paused == false);
    _;
  }

  /// @dev confirm price thresholds and amounts
  ///  holdings for holding ether
  function MenuCrowdSale(address _holdings, address _menuToken, address _teamWallet) 
    public 
  {
    require(_holdings != 0x0);
    require(_menuToken != 0x0);
    require(_teamWallet != 0x0);     
 
    icoEndTime = now + 54 days; //march 7th to april 30
    menuTeamWallet = MenuTeamWallet(_teamWallet);
    weiRaised = 0;
    menuToken = MenuToken(_menuToken);    
    holdings = _holdings;
    owner = msg.sender;
    timer = icoEndTime + 30 days; 
    cap = 23450 ether;

    
    for(uint8 i=0; i<TIERS-1; i++){
      SaleTier storage tiers = saleTier[i]; 
      tiers.tokensToBeSold = 100000000*TOKEN_DECIMALS;
      tiers.bonusAmount = (30-(10*i)); //have to account for the decimal after
    }

    saleTier[3].tokensToBeSold = 109000000*TOKEN_DECIMALS;
  }

  /// @dev Fallback function.
  /// @dev Reject random ethereum being sent to the contract.
  /// @notice allows for owner to send ethereum to the contract in the event
  /// of a refund
  function()
    public
    payable
  {
    require(msg.sender == owner);
  }

  /// @notice buyer calls this function to get tokens
  function buyTokens()
    external
    payable
    icoIsActive
    activeContract
    isValidPayload
    returns (uint8)
  {
    //purchases[msg.sender][arrIndex].remainingWei; //maybe add remainingWei calc after
    require(msg.sender != owner);
    require(ethPrice != 0);
    require(msg.value >= MIN_CONTRIBUTION);

    uint256 remainingWei = msg.value;
    uint256 totalTokensRequested;
    uint256 price = ETH_DECIMALS.div(PRICE); //wei per token
    uint256 tierRemainingTokens;
    uint256 tknsRequested;
    uint256 bonusTokenAmount;
    uint256 spentWei;
    uint256 amount;
    uint8 tierPurchased = tier;

    Participant storage participant = participants[msg.sender];

    while(remainingWei >= price && tier != TIERS) {

      SaleTier storage tiers = saleTier[tier];
      tknsRequested = remainingWei.div(price).mul(TOKEN_DECIMALS);
      bonusTokenAmount = tiers.bonusAmount.mul(tknsRequested).div(100);
      tierRemainingTokens = tiers.tokensToBeSold.sub(tiers.tokensSold);
      if(tknsRequested == tierRemainingTokens){tier++;}
      if(tknsRequested > tierRemainingTokens){
        tknsRequested = tknsRequested.sub(tierRemainingTokens);
        tiers.tokensSold += tierRemainingTokens;
        totalTokensRequested += tierRemainingTokens;
        spentWei = tierRemainingTokens.mul(price).div(TOKEN_DECIMALS);
        participant.purchases.push(Purchase(bonusTokenAmount,tiers.bonusAmount,tierPurchased));
        remainingWei = remainingWei.sub(spentWei);
        participant.contrAmount += spentWei;
        tier++;
      } else{
        tiers.tokensSold += tknsRequested;
        totalTokensRequested += tknsRequested;
        remainingWei = remainingWei.sub(tknsRequested.mul(price).div(TOKEN_DECIMALS));
        amount = msg.value.sub(remainingWei);
        participant.remainingWei += remainingWei;
        participant.contrAmount += amount;
        participant.purchases.push(Purchase(bonusTokenAmount, tiers.bonusAmount, tierPurchased));
      }   
    }
    participant.qtyTokens += totalTokensRequested;
    weiRaised += msg.value;
    LogTokensReserved(msg.sender, totalTokensRequested);
    return tier;
  }

  ///@notice I want to get the price of ethereum every time I call the buy tokens function
  ///what has to change in this function to make that happen safely
  ///param ethereum price will exclude decimals
  function setEtherPrice(uint256 _price)
    external
    onlyOwner
    {
      ethPrice = _price;
    }

  /// @notice pause specific funtions of the contract
  function pauseContract() public onlyOwner {
    paused = true;
  }

  /// @notice to unpause functions
  function unpauseContract() public onlyOwner {
    paused = false;
  } 

  ///@notice interface for founders to deny participants
  function denyWhitelist(address[] _address) 
    public 
    onlyOwner
    icoHasEnded 
  {
    for(uint8 i = 0; i < _address.length; i++){
      participants[_address[i]].wLStatus = WhitelistStatus.Denied;      
    }
  }

  ///@notice interface for founders to whitelist participants
  function OneEthWhitelist(address[] _address) 
    public 
    onlyOwner
    icoHasEnded 
  {
    for(uint8 i = 0; i < _address.length; i++){
      participants[_address[i]].wLStatus = WhitelistStatus.OneEth;      
    }
  }

  ///@notice interface for founders to whitelist participants
  function TenEthWhitelist(address[] _address) 
    public 
    onlyOwner
    icoHasEnded 
  {
    for(uint8 i = 0; i < _address.length; i++){
      participants[_address[i]].wLStatus = WhitelistStatus.OneEth;      
    }
  }

  ///@notice interface for founders to whitelist participants
  function NoLimitEthWhitelist(address[] _address) 
    public 
    onlyOwner
    icoHasEnded 
  {
    for(uint8 i = 0; i < _address.length; i++){
      participants[_address[i]].wLStatus = WhitelistStatus.NoLimitEth;      
    }
  }

  ///@notice owner withdraws ether periodically from the crowdsale contract
  function ownerWithdrawal()
    public
    onlyOwner
    returns(bool success)
  {
    LogOwnerWithdrawal(msg.sender, this.balance);//do we really want to broadcast this
    holdings.transfer(this.balance);
    return(true); 
  }

  /// @dev freeze unsold tokens for use at a later time
  /// and transfer team, owner and other internally promised tokens
  /// param total number of tokens being transfered to the freeze wallet
  function finalize(uint256 _internalTokens)
    public
    icoHasEnded
    onlyOwner
  {
    timer = now + 30 days;
    menuTeamWallet.setFreezeTime(now);
    menuToken.transferFrom(owner, menuTeamWallet, _internalTokens);  
  }

  /// @notice calculate unsold tokens for transfer to holdings to be used at a later date
  function calculateRemainingTokens()
    view
    internal
    returns (uint256)
  {
    uint256 remainingTokens;
    for(uint8 i = 0; i < TIERS; i++){
      if(saleTier[i].tokensSold < saleTier[i].tokensToBeSold){
        remainingTokens += saleTier[i].tokensToBeSold.sub(saleTier[i].tokensSold);
      }
    }
    return remainingTokens;
  }

  /// notice sends requested tokens to the whitelist person
  function claimTokens() 
    external
    icoHasEnded
  {
    Participant storage participant = participants[msg.sender];
    require(participant.wLStatus == WhitelistStatus.OneEth || participant.wLStatus == WhitelistStatus.TenEth || participant.wLStatus == WhitelistStatus.NoLimitEth);
    require(participant.qtyTokens != 0);
    uint256 tkns = participant.qtyTokens;
    participant.qtyTokens = 0;
    LogTokensClaimed(owner, msg.sender, tkns);
    menuToken.transferFrom(owner, msg.sender, tkns);
  }

  ///@notice participants can claim their bonus tokens here after the distribute Remaining Tokens function 
  function claimBonusTokens()
    public
    icoHasEnded
  {
    Participant storage participant = participants[msg.sender];
    require(now > timer);
    if(now > timer && now <= timer + 30 days){ require(participant.bonusPaidCounter < 1);}
    if(now > timer + 30 && now <= timer + 60 days){require(participant.bonusPaidCounter < 2);}
    if(now > timer + 90){require(participant.bonusPaidCounter < 3);}
   
    uint256 bonusTokens;
    uint256 purch = participant.purchases.length;

    for(uint8 i = 0; i < purch; i++){

      uint256 tenPercQtyTkns;
      if(participant.purchases[i].bonusPrcntg != 0 && participant.purchases[i].bonusTokenAmount != 0){
        tenPercQtyTkns = participant.purchases[i].bonusTokenAmount/(participant.purchases[i].bonusPrcntg/10); // should give one third one half or 1 tenth of the investment amount
        participant.purchases[i].bonusPrcntg -= 10;
      } else {
        tenPercQtyTkns = 0;
      }
      if(tenPercQtyTkns != 0){
        participant.purchases[i].bonusTokenAmount -= tenPercQtyTkns;
        bonusTokens += tenPercQtyTkns;
      } 
    }
    participant.bonusPaidCounter++;
    LogBonusTokensSent(msg.sender, bonusTokens); 
    menuToken.transferFrom(owner, msg.sender, bonusTokens); 
  }

  /// @notice no ethereum will be held in the crowdsale contract
  /// when refunds become available the amount of Ethererum needed will
  /// be manually transfered back to the crowdsale to be refunded
  function claimRefund()
    external
    activeContract
    icoHasEnded
    returns (bool success)
  {
    Participant storage participant = participants[msg.sender];
    require(participant.wLStatus == WhitelistStatus.Denied);
    require(participant.contrAmount != 0);
    uint256 sendValue = participant.contrAmount.add(participant.remainingWei);
    uint256 purch = participant.purchases.length;
    participant.remainingWei = 0;
    participant.contrAmount = 0;
    participant.qtyTokens = 0;
    for(uint8 i = 0; i < purch; i++){
        participant.purchases[i].bonusTokenAmount = 0;
        participant.purchases[i].bonusPrcntg = 0;
        participant.purchases[i].tierPurchased = 0;
    }
    LogRefundWei(msg.sender, sendValue);
    msg.sender.transfer(sendValue);
    return true;
  }

  /// @notice no ethereum will be held in the crowdsale contract
  /// when refunds become available the amount of Ethererum needed will
  /// be manually transfered back to the crowdsale to be refunded
  /// @notice only the last person that buys tokens if they deposited enought to buy more 
  /// tokens than what is available will be able to use this function
  function claimRemainingWei()
    external
    activeContract
    icoHasEnded
    returns (bool success)
  {
    Participant storage participant = participants[msg.sender];
    require(participant.wLStatus == WhitelistStatus.OneEth || participant.wLStatus == WhitelistStatus.TenEth || participant.wLStatus == WhitelistStatus.NoLimitEth);
    require(participant.remainingWei != 0);
    uint256 amount = participant.remainingWei;
    participant.remainingWei = 0;
    
    LogRefundWei(msg.sender, amount);
    msg.sender.transfer(amount);
    return true;
  }
}
