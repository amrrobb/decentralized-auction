# Decentralized Auction Platform

## Description

Welcome to the Decentralized Auction Platform named D-Auction, a smart contract-based solution for conducting decentralized auctions of non-fungible tokens (NFTs). This platform allows users to create auctions for their NFTs, participate in bidding, and claim ownership of the NFTs upon winning the auctions.

## Information

⚙️ Tech Stack: NextJS, RainbowKit, Foundry, Wagmi, Viem, Alchemy, Scaffold-ETH 2 and Typescript.

📜 Contract: https://sepolia.etherscan.io/address/0x8f86351a1394c07300f6f2071dafe931f209efc7#code

🧑🏻‍💻 Demo: https://d-auction-app-amrrobb.vercel.app/

## Features

1. **Owned NFT Display:**: The application provides visibility of all owned NFTs eligible for auction creation.
2. **Auction Creation**: Users have the ability to commence auctions for their NFTs, determining the initial price and duration.
3. **Bid Participation**: Bidders engage in ongoing auctions by submitting bids within the designated timeframe.
4. **NFT Ownership Claim**: The successful bidder can assert ownership of the NFT subsequent to triumphing in the auction.
5. **Balance Retrieval**: Participants who engaged in auctions but did not secure the winning bid retain funds within the auction contract. They can reclaim these funds by retrieving their deposited bids.

## Actors

1. **Auctioneer/Seller**: The individual who initiates an auction for their NFT by calling the `createAuction` function. The auctioneer sets the starting price and duration of the auction. Additionally, as the seller, they own the NFT being auctioned and ultimately transfer ownership to the winning bidder.

2. **Bidder**: Users who participate in ongoing auctions by placing bids on NFTs they are interested in acquiring. Bidders interact with the platform by calling the `placeBid` function.

3. **Winner**: The bidder who submits the highest bid within the auction's time frame becomes the winner of the auction. The winner can claim ownership of the NFT by calling the `claimNft` function.

## Video Demonstration

[![Watch the video](https://img.youtube.com/vi/fexsYRnLPQY/maxresdefault.jpg)](https://youtu.be/fexsYRnLPQY)
