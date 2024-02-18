"use client";

import { NFTsAuctionCreated, NFTsAuctionEnded } from "./_components";
import type { NextPage } from "next";

const Home: NextPage = () => {
  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Welcome to</span>
            <span className="block text-4xl font-bold">D-Auction</span>
          </h1>
        </div>

        <NFTsAuctionCreated />
        <NFTsAuctionEnded />
      </div>
    </>
  );
};

export default Home;
