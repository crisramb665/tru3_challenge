// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract ReceiverContract is CCIPReceiver {
    enum PayFeesIn {
        Native,
        LINK
    }

    address immutable i_router_toUse;
    address immutable i_link;

    address public tokenToMintBack = address(0x229288f40F7D88fe3Ba90978F99c654571Cd3b40);

    bytes32 latestMessageId;
    uint64 latestSourceChainSelector;
    address latestSender;
    string latestMessage;

    event MessageReceived(
        bytes32 latestMessageId,
        uint64 latestSourceChainSelector,
        address latestSender,
        string latestMessage
    );

    event MessageSent(bytes32 messageId);

    constructor(address router, address link) CCIPReceiver(router) {
        i_router_toUse = router;
        i_link = link;
    }

    receive() external payable {}

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        latestMessageId = message.messageId;
        latestSourceChainSelector = message.sourceChainSelector;
        latestSender = abi.decode(message.sender, (address));
        latestMessage = abi.decode(message.data, (string));

        if (_compareStrings(latestMessage, "Mint back")) {
            _broadcastBack(0, latestSender, PayFeesIn.Native);
        }

        emit MessageReceived(
            latestMessageId, latestSourceChainSelector, latestSender, latestMessage
        );
    }

    function _broadcastBack(uint64 destinationChainSelector, address receiver, PayFeesIn payFeesIn)
        internal
    {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encodeWithSignature(
                "mint(address,uint256)", receiver, uint256(3000000000000000000)
                ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router_toUse).getFee(destinationChainSelector, message);

        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            LinkTokenInterface(i_link).approve(i_router_toUse, fee);
            messageId = IRouterClient(i_router_toUse).ccipSend(destinationChainSelector, message);
        } else {
            messageId = IRouterClient(i_router_toUse).ccipSend{value: fee}(
                destinationChainSelector, message
            );
        }

        emit MessageSent(messageId);
    }

    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function setTokenToMintBack(address newToken) public {
        tokenToMintBack = newToken;
    }

    function getLatestMessageDetails()
        public
        view
        returns (bytes32, uint64, address, string memory)
    {
        return (latestMessageId, latestSourceChainSelector, latestSender, latestMessage);
    }
}
