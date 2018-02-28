# Testing Page
This small Truffle project creates a small web page with a node js server and connects to an RPC or IPC instance. To run this very basic system will require a few installations:
	1. Install NODEJS (Latest Version)
	2. NPM should come with it, if not install NPM(Latest Version)
	3. Install Truffle JS
	4. Install the node packages in the 'package.json' file
	5. Install TESTRPC ('ethereumjs-testrpc')
	6. If running windows, powershell might be needed, find this in your windows 10 cortana search bar, or install it
	7. If running windows, open a admin powershell window/environment

Once these are all installed on your machine, depending on your OS, it could require some minor tweaks. To run the project use the following steps:

	1. Open 2 admin command windows, and a Chrome browser window
	2. In the first window run the command 'testrpc' and it should create a private blockchain with 10 unlocked accounts etc
	3. Navigate the second window to the directory in which the project was saved, then run truffle compile, then truffle migrate
	4. If you are running windows, you will need to do ALL truffle commands in the powershell window/environment
	5. In the second command window, type 'node app.js'
	6. Go the chrome window and refresh.

The web3 calls inside of each of the node js routing calls various web3 functions and displays them in the window, and in the console. 

	1. In the 'Transfer Tokens' text box enter a number that is less than the Menu Tokens and push the 'Transfer Tokens' Button
	   - This action transfers tokens from the owner account as defined by the top address, random string of characters to the second address/account 

	2. The top text box represents the amount of tokens to pay MenuBuzz for the food/beverages purchased, Click the 'Pay Using MENU' button and it transfers the tokens back to the menubuzz platform. 

This very simple transfer function is to show how web3 on the front end interacts with the 'blockchain'. In this case the blockchain is running in the testrpc instance on your computer.
	- the communication happens through an HTTP provider, which is set at the top of the 'app.js' page, this provider can be set for local or external. Locally its set to 8545. This port lines up with the truffle.js file port.
	- currently external connections work very well with programs such as metamask, but this runs on a computer only, not a mobile device. 


To run the web project using the live public blockchain a few more things will have to be addressed. In this example we are running the Ropsten Testnet and can only pull some general data at this point. If we were to use metamask we can sign transactions, but for mobile we will find a different way to complete the token transfers/platform payments. The Truffle aspects (compile/migrate) in this case are not needed because we are pointing to an actual instance of the token (.at(token)).

	1. To see the results of the Ropsten testnet data connection uncomment line 6, and comment out line 5
	2. Comment out line 16 and 18 uncomment line 19
	3. uncomment 33 and 34, comment 37 and 38
	4. uncomment 48 and comment out 49
	5. Ignore line 61 to 84, save the file
	6. stop the node server and testrpc instance, then restart the node server
	7. Refresh the Chrome browswer and new numbers will appear, no transfers are possible at this time as we will have to address security issues etc.

All of these web3 commands can be written in regular javascript visit the site http://web3js.readthedocs.io/en/1.0/ for more info.

Please contact me via Skype as per Scotts instructions.
