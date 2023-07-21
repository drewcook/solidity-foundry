// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployBasicNFT} from "../../script/DeployBasicNFT.s.sol";
import {BasicNFT} from "../../src/BasicNFT.sol";

contract BasicNFTTest is Test {
    DeployBasicNFT public deployer;
    BasicNFT public nft;
    address public USER = makeAddr("user");
    string public constant ST_BERNARD =
        "ipfs://QmQDf2BE9RQVtvZLYf5bg37bVt1CRAwzV8dM7FmAxuDXRe";

    function setUp() public {
        deployer = new DeployBasicNFT();
        nft = deployer.run();
    }

    function testNameIsCorrect() public {
        // Test equality using hashes of abi encoded strings
        // Convert strings to bytes, then bytes to hashes, compare hashes
        string memory expected = "Doggie";
        string memory actual = nft.name();
        assert(
            keccak256(abi.encodePacked(actual)) ==
                keccak256(abi.encodePacked(expected))
        ); // Using asset equality
        assertEq(nft.name(), "Doggie"); // Using Foundry helper
    }

    function testSymbolIsCorrect() public {
        assertEq(nft.symbol(), "DOGG");
    }

    function testCanMintAndHaveBalance() public {
        vm.prank(USER);
        nft.mintNft(ST_BERNARD);
        assert(nft.balanceOf(USER) == 1);
        assert(nft.ownerOf(0) == USER);
        assert(
            keccak256(abi.encodePacked(nft.tokenURI(0))) ==
                keccak256(abi.encodePacked(ST_BERNARD))
        );
    }
}
