var MenuToken = artifacts.require("./MenuToken.sol");
var MenuCrowdSale = artifacts.require("./MenuCrowdSale.sol");

//var endtime = 1;
var holdingWallet = "0xd4592a8cf32566b3ea6dbe96c44cf3639a73ece8";
var teamWallet = "0x20d5e032a2583c74e0cca06f0e252ef01d744d0b"
//var cap = 200000000000000000000000;
//module.exports = function(deployer, network, accounts) {
module.exports = function(deployer) {
	deployer.deploy(MenuToken);
  // deployer.deploy(MenuToken).then(function() {
  //   return deployer.deploy(MenuCrowdSale, holdingWallet, MenuToken.address, teamWallet);
  // });
};

