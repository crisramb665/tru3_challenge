// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {TokenCrossChain} from "../src/TokenCrossChain.sol";
import {OriginContract} from "../src/OriginContract.sol";
import {ReceiverContract} from "../src/ReceiverContract.sol";
import {Helper} from "../script/Helper.sol";

contract Messages is Test, Helper {
    enum PayFeesInTest {
        Native,
        LINK
    }

    uint256 sepoliaFork;
    uint256 mumbaiFork;
    uint256 arbitrumSepoliaFork;

    string SEPOLIA_RPC = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
    string MUMBAI_RPC = vm.envString("POLYGON_MUMBAI_RPC_URL");
    string ARBITRUM_SEPOLIA_RPC = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");

    TokenCrossChain public firstToken;
    TokenCrossChain public secondToken;
    OriginContract public origin;
    ReceiverContract public receiver;

    event MessageSent();

    function setUp() public {
        sepoliaFork = vm.createFork(SEPOLIA_RPC);
        mumbaiFork = vm.createFork(MUMBAI_RPC);
        arbitrumSepoliaFork = vm.createFork(ARBITRUM_SEPOLIA_RPC);

        vm.selectFork(sepoliaFork);
        firstToken = new TokenCrossChain();
        origin = new OriginContract(
            routerEthereumSepolia,
            linkEthereumSepolia,
            address(firstToken)
        );
        vm.deal(address(origin), 1 ether);

        vm.selectFork(arbitrumSepoliaFork);
        receiver = new ReceiverContract(routerArbitrumSepolia, linkArbitrumSepolia);
        vm.deal(address(receiver), 1 ether);
    }

    function testForkIdDiffer() public view {
        assert(sepoliaFork != mumbaiFork);
    }

    function testSelectedFork() public {
        vm.selectFork(sepoliaFork);
        assertEq(vm.activeFork(), sepoliaFork);

        vm.selectFork(mumbaiFork);
        assertEq(vm.activeFork(), mumbaiFork);
    }

    function testContractDeployedOnRightNetwork() public {
        vm.selectFork(sepoliaFork);
        assert(address(origin) != address(0));

        vm.selectFork(mumbaiFork);
        assert(address(receiver) != address(0));
    }

    function testSetInitialConfig() public {
        vm.selectFork(sepoliaFork);
        assertEq(routerEthereumSepolia, origin.getInternalRouter());
        assertEq(linkEthereumSepolia, origin.getLinkTokenAddress());

        vm.selectFork(arbitrumSepoliaFork);
        assertEq(routerArbitrumSepolia, receiver.getInternalRouter());
        assertEq(linkArbitrumSepolia, receiver.getLinkTokenAddress());
    }

    function initialBroadcastCall() public {
        (,,, uint64 destinationChainId) = getConfigFromNetwork(SupportedNetworks.ARBITRUM_SEPOLIA);

        address tokenToMint = address(firstToken);
        address messageReceiver = address(receiver);
        string memory message = "Mint back";

        origin.mintAndBroadcast(
            destinationChainId,
            tokenToMint,
            messageReceiver,
            message,
            OriginContract.PayFeesIn.Native
        );
    }

    function testMintTokenWhenBroadcast() public {
        vm.selectFork(sepoliaFork);
        initialBroadcastCall();

        uint256 balance = firstToken.balanceOf(address(origin));
        assertEq(balance, uint256(2000000000000000000));
    }

    function testSendOutgoingMessage() public {
        vm.selectFork(sepoliaFork);
        vm.expectEmit(true, false, false, true);
        emit MessageSent();
        initialBroadcastCall();
    }

    function testReceiveIncomingMessage() public {
        vm.selectFork(sepoliaFork);
        initialBroadcastCall();

        vm.selectFork(arbitrumSepoliaFork);

        (bytes32 latestMessageId, uint64 latestSourceChainSelector,,) =
            receiver.getLatestMessageDetails();

        assertEq(
            latestMessageId, 0x0000000000000000000000000000000000000000000000000000000000000000
        );
        assertEq(latestSourceChainSelector, 0);
    }

    function testCanWithdrawFunds() public {
        vm.selectFork(sepoliaFork);
        address owner = origin.owner();
        address customBeneficiary = address(0xABC);

        assertEq(address(origin).balance, 1 ether);
        assertEq(address(customBeneficiary).balance, 0);

        vm.startPrank(owner);
        origin.withdraw(customBeneficiary);

        assertEq(address(customBeneficiary).balance, 1 ether);
        assertEq(address(origin).balance, 0);
        vm.stopPrank();
    }
}
