# NFTs

Two NFT contracts in this project, `BasicNFT` and `MoodNFT`. Basic NFT uses IPFS URIs for `tokenURI`s. Mood NFT uses base64 encoded SVGs as the images, and base64 encoded JSON as the metadata. The URIs end up looking like `data:image/svg+xml;base64,<svg encoded>` and `data:application/json;base64,<metadata encoded>`.

You can find the MoodNFT deployed to Sepolia here:

- [Etherscan Link](https://sepolia.etherscan.io/address/0xE7067EE183201761Ad28176437eD180548C164A7#code)
- [OpenSea Collection](https://testnets.opensea.io/collection/mood-nft-9)