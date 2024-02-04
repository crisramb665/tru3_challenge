// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {TokenCrossChain} from "../src/TokenCrossChain.sol";
import {OriginContract} from "../src/OriginContract.sol";
import {ReceiverContract} from "../src/ReceiverContract.sol";

contract DeployToken is Script, Helper {
    function run(SupportedNetworks source) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        TokenCrossChain tokenCC = new TokenCrossChain();

        console.log(
            "Token contract deployed on ", networks[source], "with address: ", address(tokenCC)
        );

        vm.stopBroadcast();
    }
}

contract DeployOriginContract is Script, Helper {
    function run(SupportedNetworks source, address tokenToMintBack) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, address link,,) = getConfigFromNetwork(source);

        OriginContract originContract = new OriginContract(
            router,
            link,
            tokenToMintBack
        );

        console.log(
            "OriginContract contract deployed on ",
            networks[source],
            "with address: ",
            address(originContract)
        );

        vm.stopBroadcast();
    }
}

contract DeployReceiverContract is Script, Helper {
    function run(SupportedNetworks destination) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, address link,,) = getConfigFromNetwork(destination);

        ReceiverContract receiverContract = new ReceiverContract(router, link);

        console.log(
            "OriginContract contract deployed on ",
            networks[destination],
            "with address: ",
            address(receiverContract)
        );

        vm.stopBroadcast();
    }
}

contract SendMessage is Script, Helper {
    function run(
        address payable sender,
        SupportedNetworks destination,
        address tokenAddress,
        address receiver,
        string memory message,
        OriginContract.PayFeesIn payFeesIn
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (,,, uint64 destinationChainId) = getConfigFromNetwork(destination);

        OriginContract(sender).mintAndBroadcast(
            destinationChainId, tokenAddress, receiver, message, payFeesIn
        );

        console.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );

        vm.stopBroadcast();
    }
}

contract GetLatestMessageDetails is Script, Helper {
    function run(address payable receiverContractAddress) external view {
        (
            bytes32 latestMessageId,
            uint64 latestSourceChainSelector,
            address latestSender,
            string memory latestMessage
        ) = ReceiverContract(receiverContractAddress).getLatestMessageDetails();

        console.log("Latest Message ID: ");
        console.logBytes32(latestMessageId);
        console.log("Latest Source Chain Selector: ");
        console.log(latestSourceChainSelector);
        console.log("Latest Sender: ");
        console.log(latestSender);
        console.log("Latest Message: ");
        console.log(latestMessage);
    }
}
