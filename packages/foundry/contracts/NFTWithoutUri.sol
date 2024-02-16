// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IDAuction} from "./IDAuction.sol";

contract NFTWithoutUri is ERC721 {
    IDAuction dAuction;
    uint256 private _nextTokenId;

    constructor(address _auction) ERC721("BToken", "BTK") {
        dAuction = IDAuction(_auction);
    }

    function safeMint(address to) public {
        _nextTokenId++;
        _safeMint(to, _nextTokenId);
    }

    function onERC721Received(address, /*operator*/ address, /*from*/ uint256, /*tokenId*/ bytes calldata /*data*/ )
        public
        pure
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    function claimNft(address nftContract, uint256 tokenId) external {
        dAuction.claimNft(nftContract, tokenId);
    }

    function claimNft(address nftContract, uint256 tokenId, address receiver) external {
        dAuction.claimNft(nftContract, tokenId, receiver);
    }

    function createAuction(address nftContract, uint256 tokenId, uint256 startingPrice, uint256 duration) external {
        dAuction.createAuction(nftContract, tokenId, startingPrice, duration);
    }

    function placeBid(address nftContract, uint256 tokenId) external payable {
        dAuction.placeBid{value: msg.value}(nftContract, tokenId);
    }
}
