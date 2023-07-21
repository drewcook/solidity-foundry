// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract MoodNFT is ERC721 {
    using Strings for uint256;

    error MoodNFT__CantFlipMoodIfNotOwner();

    uint256 private s_tokenCounter;
    string private s_happySvgImageUri;
    string private s_sadSvgImageUri;

    // Keep track of each token'ss mood
    enum Mood {
        HAPPY,
        SAD
    }
    mapping(uint256 => Mood) public s_tokenIdToMood;

    event FlippedMood(uint256 indexed tokenId, Mood indexed newMood);

    // Supports taking in already base64 encoded SVG data:image/svg+xml URIs
    constructor(
        string memory _happySvgImageUri,
        string memory _sadSvgImageUri
    ) ERC721("Mood NFT", "MOOD") {
        s_tokenCounter = 0;
        s_sadSvgImageUri = _sadSvgImageUri;
        s_happySvgImageUri = _happySvgImageUri;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = Mood.HAPPY;
        s_tokenCounter++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        // Determine which image data to use (happy/sad)
        string memory imageURI;
        if (s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            imageURI = s_happySvgImageUri;
        } else {
            imageURI = s_sadSvgImageUri;
        }

        // Create JSON metadata, cast to bytes, encoded to base64, and concat with baseURI to create the full token URI string
        bytes memory metadata = abi.encodePacked(
            '{"name":  "',
            name(),
            " #",
            tokenId.toString(),
            '", ',
            '"description": "An NFT that reflects the owners mood.", ',
            '"attributes": [{"trait_type": "moodiness", "value": 100}], ',
            '"image": "',
            imageURI,
            '"}'
        );

        return
            string(
                abi.encodePacked(_baseURI(), Base64.encode(bytes(metadata)))
            );
    }

    function flipMood(uint256 _tokenId) public {
        // Only allow NFT owner to change the mood
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
            revert MoodNFT__CantFlipMoodIfNotOwner();
        }

        if (s_tokenIdToMood[_tokenId] == Mood.HAPPY) {
            s_tokenIdToMood[_tokenId] = Mood.SAD;
        } else {
            s_tokenIdToMood[_tokenId] = Mood.HAPPY;
        }
        emit FlippedMood(_tokenId, s_tokenIdToMood[_tokenId]);
    }
}
