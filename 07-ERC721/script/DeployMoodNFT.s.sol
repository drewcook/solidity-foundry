// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {MoodNFT} from "../src/MoodNFT.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";

contract DeployMoodNFT is Script {
    function run() external returns (MoodNFT) {
        string memory happySvg = vm.readFile("./img/happy.svg");
        string memory sadSvg = vm.readFile("./img/sad.svg");

        vm.startBroadcast();
        MoodNFT nft = new MoodNFT(
            svgToImageURI(happySvg),
            svgToImageURI(sadSvg)
        );
        vm.stopBroadcast();

        return nft;
    }

    // Mimics the `base64 -i <file>` command
    function svgToImageURI(
        string memory svg
    ) public pure returns (string memory) {
        string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURI, svgBase64Encoded));
    }
}
