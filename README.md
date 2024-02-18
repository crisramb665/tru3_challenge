## Introduction
This is the technical challenge repository to TruWeb3, where a contract deployed on Eth Sepolia is able to mint a token, and then send a cross-chain message to another contract deployed on Polygon Mumbai. 

The contract on Polygon Mumbai will broadcast a message back to Sepolia and then it will make to the original contract to mint another token for it.

These contracts are able to be deployed on several testnets chains as well. Check the supported chains below.

## Tools used
- Foundry
- Node & NPM
- Chainlink

## Deployed contracts

- OriginContract on Sepolia: 0xe56Ff6076710F7C11A153C44aA6C6Ef5191465Cf
- ReceiverContract on Polygon Mumbai: 0xED2A66eB8b8ee904751433879Bf08657Dd445de6
- token 1 address: 0x29071bd845B6000F87c71E8062FC10bdBC88df78
- token 2 address: 0x229288f40F7D88fe3Ba90978F99c654571Cd3b40

## Getting started

1. Install packages

```
forge install
```

and

```
npm install
```

2. Compile contracts

```
forge build
```
## How to use it?

1. Create a new file by copying the `.env.example` file, and name it `.env`. Fill in your wallet's PRIVATE_KEY, and RPC URLs for at least two blockchains

```shell
PRIVATE_KEY=""
ETHEREUM_SEPOLIA_RPC_URL=""
OPTIMISM_GOERLI_RPC_URL=""
ARBITRUM_SEPOLIA_RPC_URL=""
AVALANCHE_FUJI_RPC_URL=""
POLYGON_MUMBAI_RPC_URL=""
BNB_CHAIN_TESTNET_RPC_URL=""
BASE_GOERLI_RPC_URL=""
```

NOTE: make sure you provided at least the RPC for Ethereum Sepolia and Polygon Mumbai and your EOA private key.

Once that is done, to load the variables in the `.env` file, run the following command:

```shell
source .env
```

Once this step is completed, we can test the broadcast.

2. You can execute the broadcast running this command on your terminal

```shell
forge script ./script/Execution.s.sol:SendMessage -vvv --broadcast --rpc-url ethereumSepolia --sig "run(address,uint8,address,address,string,uint8)" -- 0xe56Ff6076710F7C11A153C44aA6C6Ef5191465Cf 4 0x29071bd845B6000F87c71E8062FC10bdBC88df78 0xED2A66eB8b8ee904751433879Bf08657Dd445de6 "Mint back" 0
```
Once the execution is done, you can get the txHash where you will see the whole tx details. 

After a couple of minutes, you will be able to check the message on the destination chain running this command:

```shell
forge script ./script/Execution.s.sol:GetLatestMessageDetails -vvv --broadcast --rpc-url polygonMumbai --sig "run(address)" -- 0xED2A66eB8b8ee904751433879Bf08657Dd445de6
```

# How to run the tests?

You just simply have to run this command on your terminal:

```shell
forge test -vv => This command will display a simple test version
forge test -vvvv => This commando will display a traced test version
```