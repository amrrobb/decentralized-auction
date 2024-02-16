// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDAuction {
    event AuctionCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startingPrice,
        uint256 endTime
    );
    event AuctionEnded(
        address indexed nftContract,
        uint256 indexed tokenId,
        bool indexed success,
        address seller,
        address highestBidder,
        uint256 highestBid
    );
    event BalanceWithdrawn(address indexed user, uint256 amount);
    event BidPlaced(address indexed nftContract, uint256 indexed tokenId, address indexed bidder, uint256 bid);
    event NFTClaimed(address indexed bidder, address indexed nftContract, uint256 indexed tokenId, address receiver);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function claimNft(address nftContract, uint256 tokenId) external;
    function claimNft(address nftContract, uint256 tokenId, address receiver) external;
    function createAuction(address nftContract, uint256 tokenId, uint256 startingPrice, uint256 duration) external;
    function endAuction(address nftContract, uint256 tokenId) external;
    function getAuction(address nftContract, uint256 tokenId)
        external
        view
        returns (
            address seller,
            address highestBidder,
            uint256 startingPrice,
            uint256 highestBid,
            uint256 endTime,
            bool ended
        );
    function getBalance(address bidder) external view returns (uint256);
    function placeBid(address nftContract, uint256 tokenId) external payable;
}
