
var express	   = require('express'),
	parse	   = require('body-parser'),
	Web3       = require('web3'),
    web3       = new Web3(Web3.givenProvider || new Web3.providers.HttpProvider("http://localhost:8545")),
    //web3 = new Web3(Web3.givenProvider || new Web3.providers.HttpProvider("https://ropsten.infura.io/xBhqDV6E4xEosU5RAxJn")), 
    contract   = require("truffle-contract"),
    path       = require('path'),
    app		   = express(),    
    MenuToken  = require(path.join(__dirname, 'build/contracts/MenuToken.json'));

app.set("view engine", "ejs");
app.use(express.static(__dirname + "/public/"));
app.use(parse.json()); //needs to be used for app.post variables
app.use(parse.urlencoded({ extended:true})); //needs to be used for app.post variables
const token = '0x05815f70589681cbfc432150ab277344410e21b6';// MB roptsen token

var provider = new Web3.providers.HttpProvider("http://localhost:8545");
//var provider = new Web3.providers.HttpProvider("https://ropsten.infura.io/xBhqDV6E4xEosU5RAxJn")    

var MenuTokenContract = contract(MenuToken);
MenuTokenContract.setProvider(provider);

MenuTokenContract.currentProvider.sendAsync = function () {
    return MenuTokenContract.currentProvider.send.apply(MenuTokenContract.currentProvider, arguments);
};

var ownerAdd;
var accTwo;
var ownerBal;
var accTwoBal;

//ownerAdd = '0x879b313d063191978e81374da8f76ce038f6a6d1'; //owner of token address controled by chris barber
//accTwo = '0x592d2d571c90599a5b75ea5ec6feec8618dbea7b'; //ropsten address controled by chris barber
  
web3.eth.getAccounts(function(err, res){ // gets accounts in the TEST RPC instance
ownerAdd = res[0]; 
accTwo = res[1]; 
});

web3.eth.getBlockNumber(console.log);

app.get("/", function(req, res){
  
  console.log(ownerAdd);
  console.log(accTwo);

  //MenuTokenContract.at(token).then(async function(instance) { //use at() instead of deployed() to use the actual address
  MenuTokenContract.deployed().then(async function(instance) {
    ownerBal = await instance.balanceOf.call(ownerAdd, {from: ownerAdd}); 
    accTwoBal = await instance.balanceOf.call(accTwo, {from: ownerAdd});  
    
    console.log(ownerBal.toString());
    console.log(accTwoBal.toString());

    res.render("mainpage", {ownerBal:ownerBal, accTwoBal:accTwoBal, ownerAdd:ownerAdd, accTwo:accTwo});

		});
});


app.get("/transferred", function(req, res){
  
    var pay = req.query.transferTokens; //body needs to be used for app.post variables
    console.log(pay);
    MenuTokenContract.deployed().then(async function(instance) { //use at() instead of deployed() to use the actual address
        var transaction = await instance.transfer(accTwo, pay, {from: ownerAdd});
        console.log(transaction);
   
    }).catch(err => {console.log(err.message); });
    res.redirect("/");
});

app.post("/paid", function(req, res){
  
    var paid = req.body.payUsingMenu; //body needs to be used for app.post variableses
    console.log(paid);
    MenuTokenContract.deployed().then(async function(instance) { //use at() instead of deployed() to use the actual address
        var transaction = await instance.transfer(ownerAdd, paid, {from: accTwo});
        console.log(transaction);
   
    }).catch(err => {console.log(err.message); });
    res.redirect("/");
});

var port = process.env.PORT || 3000;
app.listen(port, function(){
	console.log("MenuBuzz TEST Server Open on 3000");
});
