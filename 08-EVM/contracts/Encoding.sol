// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Encoding {
    // In versions >=0.8.12, you can use `string.concat(stringA, stringB)`
    function combineStrings() public pure returns (string memory) {
        return string(abi.encodePacked("Hi puppy! ", "Good boy!"));
    }

    // When we send a transaction, it is "compiled" down to bytecode and sent in a "data" object of the transaction.
    // That data object now governs how future transactions will interact with it.
    // For example: https://etherscan.io/tx/0x112133a0a74af775234c077c397c8b75850ceb61840b33b23ae06b753da40490

    // Now, in order to read and understand these bytes, you need a special reader.
    // This is supposed to be a new contract? How can you tell?
    // Let's compile this contract in hardhat or remix, and you'll see the the "bytecode" output - that's that will be sent when
    // creating a contract.

    // This bytecode represents exactly the low level computer instructions to make our contract happen.
    // These low level instructions are spread out into soemthing call opcodes.

    // An opcode is going to be 2 characters that represents some special instruction, and also optionally has an input

    // You can see a list of there here:
    // https://www.evm.codes/
    // Or here:
    // https://github.com/crytic/evm-opcodes

    // This opcode reader is sometimes abstractly called the EVM - or the ethereum virtual machine.
    // The EVM basically represents all the instructions a computer needs to be able to read.
    // Any language that can compile down to bytecode with these opcodes is considered EVM compatible
    // Which is why so many blockchains are able to do this - you just get them to be able to understand the EVM and presto! Solidity smart contracts work on those blockchains.

    // Now, just the binary can be hard to read, so why not press the `assembly` button? You'll get the binary translated into
    // the opcodes and inputs for us!
    // We aren't going to go much deeper into opcodes, but they are important to know to understand how to build more complex apps.

    // How does this relate back to what we are talking about?
    // Well let's look at this encoding stuff

    // In this function, we encode the number one to what it'll look like in binary
    // Or put another way, we ABI encode it.

    ///////////////
    //  Encoding
    ///////////////

    function encodeNumber() public pure returns (bytes memory) {
        bytes memory number = abi.encode(1);
        return number;
    }

    function encodeString() public pure returns (bytes memory) {
        bytes memory str = abi.encode("some string");
        return str;
    }

    // encodePacked
    // https://forum.openzeppelin.com/t/difference-between-abi-encodepacked-string-and-bytes-string/11837
    // This is great if you want to save space, not good for calling functions.
    // You can sort of think of it as a compressor for the massive bytes object above.
    function encodeStringPacked() public pure returns (bytes memory) {
        bytes memory str = abi.encodePacked("some string");
        return str;
    }

    // This is just type casting to string
    // It's slightly different from below, and they have different gas costs
    function encodeStringBytes() public pure returns (bytes memory) {
        bytes memory str = bytes("some string");
        return str;
    }

    ///////////////
    //  Decoding
    ///////////////

    // Gas: 24612
    function decodeString() public pure returns (string memory) {
        string memory str = abi.decode(encodeString(), (string));
        return str;
    }

    ///////////////
    //  Multi
    ///////////////

    function multiEncode() public pure returns (bytes memory) {
        bytes memory strs = abi.encode(
            "some string, ",
            "it has multiple strings"
        );
        return strs;
    }

    // Gas: 24612
    function multiDecode() public pure returns (string memory, string memory) {
        (string memory str1, string memory str2) = abi.decode(
            multiEncode(),
            (string, string)
        );
        return (str1, str2);
    }

    function multiEncodePacked() public pure returns (bytes memory) {
        bytes memory strs = abi.encodePacked(
            "some string, ",
            "it has multiple strings"
        );
        return strs;
    }

    // This does not work. Solidity does support decoding packed bytes, only unpacked bytes.
    function multiDecodePacked() public pure returns (string memory) {
        string memory str = abi.decode(multiEncodePacked(), (string));
        return str;
    }

    // Instead, use casting to decode packed bytes.
    // Gas: 22313
    function multiStringCastPacked() public pure returns (string memory) {
        string memory str = string(multiEncodePacked());
        return str;
    }

    // But, abi.encoding can do much more than concatenating strings.
    // Since we know that our solidity is just going to get compiled down to this binary stuff to send a transaction...
    // We could just use this superpower to send transactions to do exactly what we want them to do.
    // Two things needed to call a contract:
    // 1. ABI
    // 2. Contract Address?
    // Well... That is true, but you don't need that massive ABI file. All we need to know is how to create the binary to call the functions that we want to call.

    // Solidity has some more "low-level" keywords, namely "staticcall" and "call". There is also "send"... but basically forget about send.
    // When you call a function, you are secretly calling "call" behind the scenes, with everything compiled down to the binary stuff for you.

    // call: How we call functions to change the state of the blockchain.
    // staticcall: This is how (at a low level) we do our "view" or "pure" function calls, and potentially don't change the blockchain state.

    // Flashback to when we withdrew ETH from our raffle:
    // - In our {} we were able to pass specific fields of a transaction, like value.
    // - In our () we were able to pass data in order to call a specific function - but there was no function we wanted to call!
    function withdraw(address recentWinner) public {
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }
    // We only sent ETH, so we didn't need to call a function!
    // If we want to call a function, or send any data, we'd do it in these parenthesis!
    // Let's look at another contract (CallAnything.sol) to explain this more...
}
