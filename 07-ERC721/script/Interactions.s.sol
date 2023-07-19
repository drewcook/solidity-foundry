// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {BasicNFT} from "../src/BasicNFT.sol";

// Interactions to work with the most recent deployment of BasicNFT, using the 'foundry-devops' package
contract MintBasicNFT is Script {
    address public minter = makeAddr("minter");
    string public constant ST_BERNARD =
        "ipfs://QmQDf2BE9RQVtvZLYf5bg37bVt1CRAwzV8dM7FmAxuDXRe";

    function mintNftOnContract(address contractAddress) public {
        console.log("msg.sender", msg.sender);
        console.log("contract address", contractAddress);
        vm.startBroadcast();
        BasicNFT(contractAddress).mintNft(ST_BERNARD);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "BasicNFT",
            block.chainid
        );
        console.log("most recent deployment: ", mostRecentDeployment);
        mintNftOnContract(mostRecentDeployment);
    }
}

contract TransferBasicNFT is Script {}
