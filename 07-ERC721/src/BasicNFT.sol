// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";

// st-bernard: ipfs://QmQDf2BE9RQVtvZLYf5bg37bVt1CRAwzV8dM7FmAxuDXRe

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
