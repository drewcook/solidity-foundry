// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";

// Example deployment: https://sepolia.etherscan.io/address/0xB30f444d85420467c020Da0Dd3bB8b7c04b9231F
// https://testnets.opensea.io/assets/sepolia/0xb30f444d85420467c020da0dd3bb8b7c04b9231f/0

contract BasicNFT is ERC721 {
    // Used as a counter for our token IDs
    uint256 private s_tokenCounter;
    // Store token ID URIs
    mapping(uint256 => string) private s_tokenIdToUri;

    constructor() ERC721("Doggie", "DOGG") {
        s_tokenCounter = 0;
    }

    // ALlows minters to choose their own token URI, mint them the current token ID and increment it by 1
    function mintNft(string memory _tokenUri) public {
        s_tokenIdToUri[s_tokenCounter] = _tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return s_tokenIdToUri[_tokenId];
    }
}
