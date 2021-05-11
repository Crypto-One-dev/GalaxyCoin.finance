GalaxyCoin.sol => Galaxy Coin Contract


GalaxyLottery.sol => Galaxy Coin Lottery Contract

# Install
`npm install`

`cp secrets.json.sample secrets.json`

Add you api key, mnemonic,etherscanApiKey (https://bscscan.com/ you get from here), privateKey

`npx hardhat clean`

`npx hardhat compile`

`npx hardhat run --network bsctestnet scripts/deploy.js `


* you need to update your own ETHERSCAN API KEY
* modify package.json for verify script to right network and right contract deploy address

`npx hardhat  verify --network bsctestnet contractAddress`

# Mainnet network
`npx hardhat run --network bsc scripts/deploy.js `


* you need to update your own ETHERSCAN API KEY
* modify package.json for verify script to right network and right contract deploy address

`npx hardhat  verify --network bsc contractAddress`


# refer to
https://www.binance.org/en/blog/using-hardhat-for-binance-smart-chain/
# check deploy
You can check the deployment status here: https://bscscan.com/ or https://testnet.bscscan.com/




# TODO, 
* Domain_saperator should be changed for each ChainID.

Develop by : Nishant Bijani
