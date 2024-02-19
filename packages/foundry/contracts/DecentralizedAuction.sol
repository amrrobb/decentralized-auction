// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Decentralized Auction
 * @author Ammar Robbani (Robbyn)
 * @notice This smart contract facilitates decentralized auctions for non-fungible tokens (NFTs).
 * The highest bidder acquires the NFT by submitting the highest bid within the specified time frame.
 * @dev This contract manages auctions for NFTs owned by individuals.
 * Auctions are conducted in a decentralized manner, ensuring fairness and transparency.
 * The process for conducting an auction is as follows:
 * 1. The auctioneer grants approval for the NFT to be included in an auction.
 * 2. An auction is initiated, allowing the auctioneer to set the starting price and duration.
 * 3. Bidders participate by submitting bids within the designated time period, competing against one another.
 * 4. The auction concludes when the time limit expires.
 * 5. The NFT is transferred to the highest bidder upon auction completion.
 */

contract DecentralizedAuction is Ownable {
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
    // Fee percentage for the contract owner is 0.5%
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
    /**
     * @notice Creates a new auction for a specified non-fungible token (NFT).
     * @dev This function creates an auction for the given NFT, allowing the auctioneer to set the starting price and duration.
     * Only the owner of the NFT can initiate the auction, and the NFT must be approved for transfer to this contract.
     * @dev Reverts if:
     *      - The caller is not the owner of the NFT.
     *      - The NFT has not been approved for transfer to this contract.
     *
     * Upon successful auction creation, an event is emitted.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT being auctioned.
     * @param startingPrice The starting price of the auction.
     * @param duration The duration of the auction, specified in seconds.
     */
    function createAuction(address nftContract, uint256 tokenId, uint256 startingPrice, uint256 duration)
        external
        auctionShouldNotExists(nftContract, tokenId)
    {
        IERC721 nft = IERC721(nftContract);

        if (nft.ownerOf(tokenId) != msg.sender) {
            revert DecentralizedAuction__InvalidNFTOwner();
        }
        if (nft.getApproved(tokenId) != address(this)) {
            revert DecentralizedAuction__MissingApproval();
        }

        uint256 endTime = block.timestamp + duration;
        s_auctions[nftContract][tokenId] = Auction({
            seller: msg.sender,
            highestBidder: address(0),
            highestBid: 0,
            startingPrice: startingPrice,
            endTime: endTime,
            ended: false
        });

        emit AuctionCreated(nftContract, tokenId, msg.sender, startingPrice, endTime);
    }

    /**
     * @notice Allows a bidder to place a bid on a specified auction for a non-fungible token (NFT).
     * @dev This function enables bidders to participate in an ongoing auction by submitting bids.
     * Bidders must send the required bid amount along with the transaction.
     * @dev Reverts if:
     *      - The auction has ended.
     *      - The bid amount is insufficient compared to the current highest bid or the starting price.
     * Upon a successful bid placement, an event is emitted.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT being auctioned.
     */
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

    /**
     * @notice Ends the specified auction for a non-fungible token (NFT).
     * @dev This function finalizes the auction process by determining the auction outcome and transferring funds accordingly.
     * @dev Reverts if:
     *      - The auction has already ended.
     *      - The auction end time has not yet been reached.
     * Upon auction completion, an event is emitted, indicating the success of the auction and relevant transaction details.
     * If the auction is unsuccessful (i.e., no bids were placed), the auction is removed.
     * If the auction is successful, funds are distributed as follows:
     *      - A fee is deducted from the winning bid and transferred to the contract owner.
     *      - The remaining amount is transferred to the seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT being auctioned.
     */
    function endAuction(address nftContract, uint256 tokenId) external {
        Auction storage auction = s_auctions[nftContract][tokenId];
        if (auction.ended) {
            revert DecentralizedAuction__AuctionHasEnded(nftContract, tokenId);
        }
        if (auction.endTime > block.timestamp) {
            revert DecentralizedAuction__AuctionHasNotEnded(nftContract, tokenId);
        }
        bool success = auction.highestBidder != address(0);

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
    /**
     * @notice Allows the successful bidder to claim ownership of the NFT after winning the auction.
     * @dev This function transfers the ownership of the NFT from the seller to the winning bidder.
     * It emits an event to signify the successful transfer of ownership.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT being claimed.
     */

    function claimNft(address nftContract, uint256 tokenId) external {
        (address seller, address bidder) = _claimNFT(nftContract, tokenId);
        emit NFTClaimed(bidder, nftContract, tokenId, bidder);

        IERC721(nftContract).safeTransferFrom(seller, bidder, tokenId);
    }

    /**
     * @notice Allows the successful bidder to specify a receiver address for claiming ownership of the NFT.
     * @dev This function transfers the ownership of the NFT from the seller to the specified receiver address.
     * It emits an event to signify the successful transfer of ownership to the receiver.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT being claimed.
     * @param receiver The address of the receiver who will claim ownership of the NFT.
     */
    function claimNft(address nftContract, uint256 tokenId, address receiver) external {
        (address seller, address bidder) = _claimNFT(nftContract, tokenId);
        emit NFTClaimed(bidder, nftContract, tokenId, receiver);

        IERC721(nftContract).safeTransferFrom(seller, receiver, tokenId);
    }

    /**
     * @notice Allows users to withdraw their available balance from the auction contract.
     * @dev This function transfers the available balance of the caller from the auction contract to their address.
     * Reverts if the caller's balance is insufficient for withdrawal.
     * Emits an event upon successful balance withdrawal.
     */
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
    /**
     * @dev Internal function to facilitate the claiming of the NFT by the highest bidder.
     * This function should only be called if the auction is successful.
     * The process of returning the NFT to the auctioneer will be handled in the `endAuction` function
     * if the there are no bids placed for this auction.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT being claimed.
     * @return seller The address of the seller/auctioneer.
     * @return bidder The address of the highest bidder.
     */
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

    /**
     * @dev Internal function to remove an auction entry from the storage.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT associated with the auction.
     */
    function _removeAuction(address nftContract, uint256 tokenId) internal {
        delete s_auctions[nftContract][tokenId];
    }

    ////////////////////////////////////////
    //////    Pure & View Functions   //////
    ////////////////////////////////////////
    /**
     * @notice Retrieves the available balance of a bidder.
     * @param bidder The address of the bidder.
     * @return The available balance of the bidder.
     */
    function getBalance(address bidder) external view returns (uint256) {
        return s_balances[bidder];
    }

    /**
     * @notice Retrieves the details of an ongoing auction for a specific NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @return seller The address of the seller/auctioneer.
     * @return highestBidder The address of the highest bidder.
     * @return startingPrice The starting price of the auction.
     * @return highestBid The current highest bid in the auction.
     * @return endTime The timestamp indicating the end time of the auction.
     * @return ended A boolean indicating whether the auction has ended.
     */
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
