// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {TokenCrossChain} from "../src/TokenCrossChain.sol";
import {OriginContract} from "../src/OriginContract.sol";

contract DeployOriginContract is Script, Helper {
    function run(SupportedNetworks source) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address initialTokenOwner = address(0xbc6b93f3Aba28CD04B96c50b0F0ac53a24564718);
        TokenCrossChain tokenCC = new TokenCrossChain(initialTokenOwner);

        console.log(
            "Token contract deployed on ", networks[source], "with address: ", address(tokenCC)
        );

        (address router, address link,,) = getConfigFromNetwork(source);

        OriginContract originContract = new OriginContract(
            router,
            link
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

contract SendMessage is Script, Helper {
    function run(
        address payable sender,
        SupportedNetworks destination,
        address receiver,
        string memory message,
        OriginContract.PayFeesIn payFeesIn
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (,,, uint64 destinationChainId) = getConfigFromNetwork(destination);

        bytes32 messageId =
            OriginContract(sender).send(destinationChainId, receiver, message, payFeesIn);

        console.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        console.logBytes32(messageId);

        vm.stopBroadcast();
    }
}
