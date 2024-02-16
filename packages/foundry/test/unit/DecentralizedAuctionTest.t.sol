// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DecentralizedAuction} from "../../contracts/DecentralizedAuction.sol";
import {DeployDecentralizedAuctionScript} from "../../script/DeployDecentralizedAuction.s.sol";
import {MockERC721} from "../mocks/MockERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DecentralizedAuctionTest is Test {
    DecentralizedAuction decentralizedAuction;
    DeployDecentralizedAuctionScript deployAuction;
    MockERC721 mockNft;
    MockERC721 mockNft2;

    struct Auction {
        address seller;
        address highestBidder;
        uint256 startingPrice;
        uint256 highestBid;
        uint256 endTime;
        bool ended;
    }
    // bool claimed;

    address ownerAuctionContract;
    address ownerNftContract = makeAddr("ownerNFT");
    address ownerNftContract2 = makeAddr("ownerNFT2");
    address mockUser = makeAddr("user1");
    address mockUser2 = makeAddr("user2");
    address bidder = makeAddr("bidder");

    uint256 constant FEE_PERCENTAGE = 5;
    uint256 constant FEE_PRECISION = 1000;
    uint256 constant STARTING_PRICE = 0.01 ether;
    uint256 constant DURATION = 60; // 60 seconds
    uint256 constant STARTING_TOKEN_ID = 1;
    uint256 constant BALANCE = 10 ether;

    /**
     * Events
     */
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
    event BalanceWithdrawn(address indexed bidder);
    event NFTClaimed(address indexed bidder, address indexed nftContract, uint256 indexed tokenId, address receiver);

    function setUp() public {
        deployAuction = new DeployDecentralizedAuctionScript();
        decentralizedAuction = deployAuction.run();
        ownerAuctionContract = decentralizedAuction.owner();
        mockNft = new MockERC721(ownerNftContract);
        mockNft2 = new MockERC721(ownerNftContract2);
    }

    modifier nftMinted(uint256 _tokenId) {
        vm.startPrank(ownerNftContract);
        // minting a new token
        mockNft.mint(mockUser, _tokenId);
        vm.stopPrank();
        // vm.startPrank(ownerNftContract2);
        // mockNft2.mint(mockUser2, STARTING_TOKEN_ID);
        // vm.stopPrank();

        _;
    }

    modifier auctionCreated() {
        vm.startPrank(mockUser);
        // giving approval to decentralized auction contract
        mockNft.approve(address(decentralizedAuction), STARTING_TOKEN_ID);
        decentralizedAuction.createAuction(address(mockNft), STARTING_TOKEN_ID, STARTING_PRICE, DURATION);
        vm.stopPrank();
        _;
    }

    modifier bidPlaced() {
        uint256 bid = STARTING_PRICE * 2;

        startHoax(bidder, BALANCE);
        decentralizedAuction.placeBid{value: bid}(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();
        _;
    }

    modifier auctionEnded() {
        vm.startPrank(mockUser);
        vm.warp(block.timestamp + DURATION + 1);
        vm.roll(block.number + 1);

        decentralizedAuction.endAuction(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();
        _;
    }

    function testCreateAuctionFailedNotOwningNFT() public {
        vm.startPrank(ownerNftContract);
        // minting a new token
        mockNft.mint(vm.addr(1), 1);
        vm.stopPrank();

        vm.expectRevert(DecentralizedAuction.DecentralizedAuction__InvalidNFTOwner.selector);
        vm.startPrank(mockUser);
        decentralizedAuction.createAuction(address(mockNft), STARTING_TOKEN_ID, STARTING_PRICE, DURATION);
        vm.stopPrank();
    }

    function testCreateAuctionFailedMissingApproval() public {
        // mint nft
        vm.startPrank(ownerNftContract);
        mockNft.mint(mockUser, STARTING_TOKEN_ID);
        vm.stopPrank();

        vm.expectRevert(DecentralizedAuction.DecentralizedAuction__MissingApproval.selector);

        vm.startPrank(mockUser);
        decentralizedAuction.createAuction(address(mockNft), STARTING_TOKEN_ID, STARTING_PRICE, DURATION);
        vm.stopPrank();
    }

    function testCreateAuctionWithOwningNFT() public nftMinted(STARTING_TOKEN_ID) {
        uint256 actualEndTime = block.timestamp + DURATION;

        vm.startPrank(mockUser);
        mockNft.approve(address(decentralizedAuction), STARTING_TOKEN_ID);

        vm.expectEmit(true, true, true, true);
        emit AuctionCreated(address(mockNft), STARTING_TOKEN_ID, mockUser, STARTING_PRICE, actualEndTime);

        decentralizedAuction.createAuction(address(mockNft), STARTING_TOKEN_ID, STARTING_PRICE, DURATION);
        vm.stopPrank();

        (address seller, address highestBidder, uint256 startingPrice,, uint256 endTime,) =
            decentralizedAuction.getAuction(address(mockNft), STARTING_TOKEN_ID);

        assertEq(mockUser, seller);
        assertEq(highestBidder, address(0));
        assertEq(startingPrice, STARTING_PRICE);
        assertEq(endTime, actualEndTime);
    }

    function testCreateAuctionFailedWithAuctionedNFT() public nftMinted(STARTING_TOKEN_ID) {
        vm.startPrank(mockUser);
        // Approval
        mockNft.approve(address(decentralizedAuction), STARTING_TOKEN_ID);
        // 1st creation
        decentralizedAuction.createAuction(address(mockNft), STARTING_TOKEN_ID, STARTING_PRICE, DURATION);

        vm.expectRevert(
            abi.encodeWithSelector(
                DecentralizedAuction.DecentralizedAuction__AuctionExist.selector, address(mockNft), STARTING_TOKEN_ID
            )
        );
        // 2nd creation
        decentralizedAuction.createAuction(address(mockNft), STARTING_TOKEN_ID, STARTING_PRICE, DURATION);
        vm.stopPrank();
    }

    function testPlaceBidFailedAfterTimePassed() public nftMinted(STARTING_TOKEN_ID) auctionCreated {
        vm.startPrank(mockUser);
        vm.warp(block.timestamp + DURATION + 1);
        vm.roll(block.number + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                DecentralizedAuction.DecentralizedAuction__AuctionHasEnded.selector, address(mockNft), STARTING_TOKEN_ID
            )
        );
        decentralizedAuction.placeBid(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();
    }

    function testPlaceBidFailedBidLessThanStartingPrice() public nftMinted(STARTING_TOKEN_ID) auctionCreated {
        vm.expectRevert(DecentralizedAuction.DecentralizedAuction__InsuficientValue.selector);
        vm.startPrank(mockUser);
        decentralizedAuction.placeBid{value: 0}(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();
    }

    function testPlaceBidFailedCompeteWithHighestBidder() public nftMinted(STARTING_TOKEN_ID) auctionCreated {
        startHoax(vm.addr(1), BALANCE);
        decentralizedAuction.placeBid{value: STARTING_PRICE + 100}(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();

        vm.expectRevert(DecentralizedAuction.DecentralizedAuction__InsuficientValue.selector);

        startHoax(vm.addr(2), BALANCE);
        decentralizedAuction.placeBid{value: STARTING_PRICE - 100}(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();
    }

    function testPlaceBidSuccess() public nftMinted(STARTING_TOKEN_ID) auctionCreated {
        uint256 bid = STARTING_PRICE + 100;

        vm.expectEmit(true, true, true, true);
        emit BidPlaced(address(mockNft), STARTING_TOKEN_ID, bidder, bid);

        startHoax(bidder, BALANCE);
        decentralizedAuction.placeBid{value: bid}(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();

        (address seller, address highestBidder, uint256 startingPrice, uint256 highestBid,,) =
            decentralizedAuction.getAuction(address(mockNft), STARTING_TOKEN_ID);

        assertEq(mockUser, seller);
        assertEq(highestBidder, bidder);
        assertEq(startingPrice, STARTING_PRICE);
        assertEq(highestBid, bid);
    }

    function testEndAuctionFailedWhenTimeHasNotPassed() public nftMinted(STARTING_TOKEN_ID) auctionCreated bidPlaced {
        vm.startPrank(vm.addr(1));
        vm.expectRevert(
            abi.encodeWithSelector(
                DecentralizedAuction.DecentralizedAuction__AuctionHasNotEnded.selector,
                address(mockNft),
                STARTING_TOKEN_ID
            )
        );

        decentralizedAuction.endAuction(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();
    }

    function testEndAuctionIfThereIsABiddingPlaced() public nftMinted(STARTING_TOKEN_ID) auctionCreated bidPlaced {
        vm.startPrank(vm.addr(1));
        vm.warp(block.timestamp + DURATION + 1);
        vm.roll(block.number + 1);

        (address seller, address highestBidder,, uint256 highestBid,,) =
            decentralizedAuction.getAuction(address(mockNft), STARTING_TOKEN_ID);

        vm.expectEmit(true, true, true, true);
        emit AuctionEnded(address(mockNft), STARTING_TOKEN_ID, true, seller, highestBidder, highestBid);

        decentralizedAuction.endAuction(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();

        (,,,,, bool ended) = decentralizedAuction.getAuction(address(mockNft), STARTING_TOKEN_ID);

        assert(ended);

        uint256 fee = highestBid * FEE_PERCENTAGE / FEE_PRECISION;
        uint256 received = highestBid - fee;

        uint256 balanceSeller = decentralizedAuction.getBalance(seller);
        uint256 balanceOwner = decentralizedAuction.getBalance(ownerAuctionContract);

        assertEq(balanceSeller, received);
        assertEq(balanceOwner, fee);
    }

    function testEndAuctionIfThereIsNoBiddingPlaced() public nftMinted(STARTING_TOKEN_ID) auctionCreated {
        vm.startPrank(vm.addr(1));
        vm.warp(block.timestamp + DURATION + 1);
        vm.roll(block.number + 1);

        (address seller, address highestBidder,, uint256 highestBid,,) =
            decentralizedAuction.getAuction(address(mockNft), STARTING_TOKEN_ID);

        vm.expectEmit(true, true, true, true);
        emit AuctionEnded(address(mockNft), STARTING_TOKEN_ID, false, seller, highestBidder, highestBid);

        decentralizedAuction.endAuction(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();

        (address newSeller,,,,,) = decentralizedAuction.getAuction(address(mockNft), STARTING_TOKEN_ID);

        assertEq(newSeller, address(0));
    }

    function testEndAuctionFailedWhenAuctionAlreadyEnded()
        public
        nftMinted(STARTING_TOKEN_ID)
        auctionCreated
        bidPlaced
    {
        vm.startPrank(vm.addr(1));
        vm.warp(block.timestamp + DURATION + 1);
        vm.roll(block.number + 1);

        decentralizedAuction.endAuction(address(mockNft), STARTING_TOKEN_ID);

        vm.expectRevert(
            abi.encodeWithSelector(
                DecentralizedAuction.DecentralizedAuction__AuctionHasEnded.selector, address(mockNft), STARTING_TOKEN_ID
            )
        );

        decentralizedAuction.endAuction(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();
    }

    function testClaimNFTFailedNotMsgSender()
        public
        nftMinted(STARTING_TOKEN_ID)
        auctionCreated
        bidPlaced
        auctionEnded
    {
        address newAddress = vm.addr(1);
        vm.startPrank(newAddress);
        vm.expectRevert(DecentralizedAuction.DecentralizedAuction__InvalidNFTOwner.selector);
        decentralizedAuction.claimNft(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();
    }

    function testClaimNftSuccess() public nftMinted(STARTING_TOKEN_ID) auctionCreated bidPlaced auctionEnded {
        vm.startPrank(bidder);

        vm.expectEmit(true, true, true, true);
        emit NFTClaimed(bidder, address(mockNft), STARTING_TOKEN_ID, bidder);

        decentralizedAuction.claimNft(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();

        IERC721 nft = IERC721(address(mockNft));
        (address seller,,,,,) = decentralizedAuction.getAuction(address(mockNft), STARTING_TOKEN_ID);

        assertEq(nft.ownerOf(STARTING_TOKEN_ID), bidder);
        assertEq(seller, address(0));
    }

    function testClaimNftThatAlreadyClaimed()
        public
        nftMinted(STARTING_TOKEN_ID)
        auctionCreated
        bidPlaced
        auctionEnded
    {
        vm.startPrank(bidder);
        decentralizedAuction.claimNft(address(mockNft), STARTING_TOKEN_ID);

        vm.expectRevert(
            abi.encodeWithSelector(
                DecentralizedAuction.DecentralizedAuction__AuctionNotExist.selector, address(mockNft), STARTING_TOKEN_ID
            )
        );

        decentralizedAuction.claimNft(address(mockNft), STARTING_TOKEN_ID);
        vm.stopPrank();
    }

    function testWithdrawBalanceNotEnoughBalance() public {
        vm.startPrank(vm.addr(1));

        vm.expectRevert(DecentralizedAuction.DecentralizedAuction__InsuficientBalance.selector);

        decentralizedAuction.withdrawBalance();
        vm.stopPrank();
    }

    function testWithdrawBalanceSuccess() public nftMinted(STARTING_TOKEN_ID) auctionCreated bidPlaced auctionEnded {
        uint256 contractBalance = decentralizedAuction.getBalance(ownerAuctionContract);
        uint256 prevUserBalance = ownerAuctionContract.balance;

        vm.startPrank(ownerAuctionContract);
        decentralizedAuction.withdrawBalance();
        vm.stopPrank();

        uint256 currUserBalance = ownerAuctionContract.balance;
        assertEq(currUserBalance, contractBalance + prevUserBalance);
    }
}
