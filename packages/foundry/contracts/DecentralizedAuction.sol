// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {console} from "forge-std/Test.sol";

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

contract DecentralizedAuction is /*IERC721Receiver, */ Ownable {
    ///////////////////////////
    //////    Errors     //////
    ///////////////////////////
    error DecentralizedAuction__AuctionHasEnded(address nftContract, uint256 tokenId);
    error DecentralizedAuction__AuctionHasNotEnded(address nftContract, uint256 tokenId);
    error DecentralizedAuction__AuctionExist(address nftContract, uint256 tokenId);
    error DecentralizedAuction__AuctionNotExist(address nftContract, uint256 tokenId);
    error DecentralizedAuction__InvalidNFTOwner();
    error DecentralizedAuction__MissingApproval();
    error DecentralizedAuction__InsuficientBalance();
    error DecentralizedAuction__InsuficientValue();
    error DecentralizedAuction__TransferFailed();
    error DecentralizedAuction__NFTHasClaimed();

    /////////////////////////////////////
    //////    Type Declaratios     //////
    /////////////////////////////////////
    struct Auction {
        address seller;
        address highestBidder;
        uint256 startingPrice;
        uint256 highestBid;
        uint256 endTime;
        bool ended;
    }

    /////////////////////////////////////
    //////    State Variables     //////
    /////////////////////////////////////
    mapping(address nftContract => mapping(uint256 tokenId => Auction auction)) private s_auctions;
    mapping(address user => uint256 amount) private s_balances;
    uint256 constant FEE_PERCENTAGE = 5;
    uint256 constant FEE_PRECISION = 1000;

    ///////////////////////////
    //////    Events     //////
    ///////////////////////////
    event AuctionCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startingPrice,
        uint256 endTime
    );
    // string tokenURI

    event BidPlaced(address indexed nftContract, uint256 indexed tokenId, address indexed bidder, uint256 bid);
    event AuctionEnded(
        address indexed nftContract,
        uint256 indexed tokenId,
        bool indexed success,
        address seller,
        address highestBidder,
        uint256 highestBid
    );
    event BalanceWithdrawn(address indexed user, uint256 amount);
    event NFTClaimed(address indexed bidder, address indexed nftContract, uint256 indexed tokenId, address receiver);

    constructor(address _owner) Ownable(_owner) {}

    //////////////////////////////
    //////    Modifiers     //////
    //////////////////////////////
    modifier auctionShouldNotExists(address _nftContract, uint256 _tokenId) {
        if (s_auctions[_nftContract][_tokenId].seller != address(0)) {
            revert DecentralizedAuction__AuctionExist(_nftContract, _tokenId);
        }
        _;
    }

    modifier auctionShouldExists(address _nftContract, uint256 _tokenId) {
        if (s_auctions[_nftContract][_tokenId].seller == address(0)) {
            revert DecentralizedAuction__AuctionNotExist(_nftContract, _tokenId);
        }
        _;
    }

    ////////////////////////////
    //////    Functions   //////
    ////////////////////////////

    /////////////////////////////////////
    //////    External Functions   //////
    /////////////////////////////////////
    function createAuction(address nftContract, uint256 tokenId, uint256 startingPrice, uint256 duration)
        external
        auctionShouldNotExists(nftContract, tokenId)
    {
        // Checks

        // ERC721URIStorage nft = ERC721URIStorage(nftContract);
        IERC721 nft = IERC721(nftContract);

        if (nft.ownerOf(tokenId) != msg.sender) {
            revert DecentralizedAuction__InvalidNFTOwner();
        }
        if (nft.getApproved(tokenId) != address(this)) {
            revert DecentralizedAuction__MissingApproval();
        }
        // string memory tokenURI = nft.tokenURI(tokenId);
        // string memory tokenURI = IERC721(nftContract).tokenURI(tokenId);

        // Effects
        uint256 endTime = block.timestamp + duration;
        s_auctions[nftContract][tokenId] = Auction({
            seller: msg.sender,
            highestBidder: address(0),
            highestBid: 0,
            startingPrice: startingPrice,
            endTime: endTime,
            ended: false
        });
        // claimed: false

        emit AuctionCreated(nftContract, tokenId, msg.sender, startingPrice, endTime /*, tokenURI*/ );
    }

    function placeBid(address nftContract, uint256 tokenId)
        external
        payable
        auctionShouldExists(nftContract, tokenId)
    {
        Auction storage auction = s_auctions[nftContract][tokenId];
        if (block.timestamp > auction.endTime) {
            revert DecentralizedAuction__AuctionHasEnded(nftContract, tokenId);
        }
        if (
            (msg.value < auction.startingPrice && auction.highestBidder == address(0))
                || (msg.value < auction.highestBid && auction.highestBidder != address(0))
        ) {
            revert DecentralizedAuction__InsuficientValue();
        }

        if (auction.highestBidder != address(0)) {
            s_balances[auction.highestBidder] += auction.highestBid;
        }
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit BidPlaced(nftContract, tokenId, msg.sender, msg.value);
    }

    function endAuction(address nftContract, uint256 tokenId) external {
        Auction storage auction = s_auctions[nftContract][tokenId];
        if (auction.ended) {
            revert DecentralizedAuction__AuctionHasEnded(nftContract, tokenId);
        }
        if (auction.endTime > block.timestamp) {
            revert DecentralizedAuction__AuctionHasNotEnded(nftContract, tokenId);
        }
        bool success = auction.highestBidder != address(0);

        // need check behavior transfer nft when owner send nft before approved contract
        emit AuctionEnded(nftContract, tokenId, success, auction.seller, auction.highestBidder, auction.highestBid);

        if (!success) {
            _removeAuction(nftContract, tokenId);
        } else {
            auction.ended = true;
            uint256 fee = auction.highestBid * FEE_PERCENTAGE / FEE_PRECISION;
            uint256 received = auction.highestBid - fee;
            s_balances[auction.seller] += received;
            s_balances[this.owner()] += fee;
        }
    }

    function claimNft(address nftContract, uint256 tokenId) external {
        (address seller, address bidder) = _claimNFT(nftContract, tokenId);
        emit NFTClaimed(bidder, nftContract, tokenId, bidder);

        IERC721(nftContract).safeTransferFrom(seller, bidder, tokenId);
    }

    function claimNft(address nftContract, uint256 tokenId, address receiver) external {
        (address seller, address bidder) = _claimNFT(nftContract, tokenId);
        emit NFTClaimed(bidder, nftContract, tokenId, receiver);

        IERC721(nftContract).safeTransferFrom(seller, receiver, tokenId);
    }

    function withdrawBalance() external {
        uint256 value = s_balances[msg.sender];
        s_balances[msg.sender] = 0;

        if (value == 0) {
            revert DecentralizedAuction__InsuficientBalance();
        }
        emit BalanceWithdrawn(msg.sender, value);

        (bool success,) = msg.sender.call{value: value}("");
        if (!success) {
            revert DecentralizedAuction__TransferFailed();
        }
    }

    /////////////////////////////////////
    //////    Internal Functions   //////
    /////////////////////////////////////

    // @notice this function should not be called if the auction is not success
    // the process of return to the auctioner will be processed in `endAuction` function
    function _claimNFT(address nftContract, uint256 tokenId)
        internal
        auctionShouldExists(nftContract, tokenId)
        returns (address seller, address bidder)
    {
        Auction storage auction = s_auctions[nftContract][tokenId];
        if (auction.highestBidder != msg.sender) {
            revert DecentralizedAuction__InvalidNFTOwner();
        }
        seller = auction.seller;
        bidder = auction.highestBidder;
        _removeAuction(nftContract, tokenId);
    }

    function _removeAuction(address nftContract, uint256 tokenId) internal {
        delete s_auctions[nftContract][tokenId];
    }

    ////////////////////////////////////////
    //////    Pure & View Functions   //////
    ////////////////////////////////////////

    // function onERC721Received(address, /*operator*/ address, /*from*/ uint256, /*tokenId*/ bytes calldata /*data*/ )
    //     public
    //     pure
    //     returns (bytes4)
    // {
    //     return this.onERC721Received.selector;
    // }

    function getBalance(address bidder) external view returns (uint256) {
        return s_balances[bidder];
    }

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
        )
    {
        Auction storage auction = s_auctions[nftContract][tokenId];

        seller = auction.seller;
        highestBidder = auction.highestBidder;
        startingPrice = auction.startingPrice;
        highestBid = auction.highestBid;
        ended = auction.ended;
        endTime = auction.endTime;
    }
}
