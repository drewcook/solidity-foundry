// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {BasicNFT} from "../src/BasicNFT.sol";
import {MoodNFT} from "../src/MoodNFT.sol";

// Interactions to work with the most recent deployment of BasicNFT, using the 'foundry-devops' package
contract MintBasicNFT is Script {
    string public constant ST_BERNARD =
        "ipfs://QmQDf2BE9RQVtvZLYf5bg37bVt1CRAwzV8dM7FmAxuDXRe";

    function mintNftOnContract(address contractAddress) public {
        console.log("msg.sender", msg.sender);
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

contract MintMoodNFT is Script {
    function mintNftOnContract(address contractAddress) public {
        console.log("msg.sender", msg.sender);
        vm.startBroadcast();
        MoodNFT(contractAddress).mintNft();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "MoodNFT",
            block.chainid
        );
        console.log("most recent deployment: ", mostRecentDeployment);
        mintNftOnContract(mostRecentDeployment);
    }
}

contract FlipMoodNFT is Script {
    function flipNftOnContract(
        address contractAddress,
        uint256 tokenId
    ) public {
        console.log("msg.sender", msg.sender);
        vm.startBroadcast();
        MoodNFT(contractAddress).flipMood(tokenId);
        vm.stopBroadcast();
    }

    function run(uint256 tokenId) external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "MoodNFT",
            block.chainid
        );
        console.log("most recent deployment: ", mostRecentDeployment);
        flipNftOnContract(mostRecentDeployment, tokenId);
    }
}
