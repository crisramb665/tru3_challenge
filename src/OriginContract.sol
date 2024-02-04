// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Withdraw} from "./Withdraw.sol";
import {ITokenCrossChain} from "./ITokenCrossChain.sol";

contract OriginContract is Withdraw, CCIPReceiver {
    enum PayFeesIn {
        Native,
        LINK
    }

    address immutable i_router_toUse;
    address immutable i_link;

    bytes32 latestMessageId;
    uint64 latestSourceChainSelector;
    address latestSender;
    string latestMessage;

    ITokenCrossChain public tokenToMintBack;

    event MessageSent(bytes32 messageId);
    event MintToTokenBackSuccessful();

    error MintNotSuccessfull();
    error MessageBackNotReceived();

    constructor(address router, address link, address initialokenToMintBack) CCIPReceiver(router) {
        i_router_toUse = router;
        i_link = link;
        tokenToMintBack = ITokenCrossChain(initialokenToMintBack);
    }

    receive() external payable {}

    function mintAndBroadcast(
        uint64 destinationChainSelector,
        address tokenAddress,
        address receiver,
        string memory messageText,
        PayFeesIn payFeesIn
    ) external {
        ITokenCrossChain(tokenAddress).mint(address(this), uint256(2000000000000000000));

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(messageText),
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
            messageId =
                IRouterClient(i_router).ccipSend{value: fee}(destinationChainSelector, message);
        }

        emit MessageSent(messageId);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        (bool success,) = address(tokenToMintBack).call(message.data);
        if (!success) revert MessageBackNotReceived();
        emit MintToTokenBackSuccessful();
    }

    function getLatestMessageDetails()
        public
        view
        returns (bytes32, uint64, address, string memory)
    {
        return (latestMessageId, latestSourceChainSelector, latestSender, latestMessage);
    }
}
