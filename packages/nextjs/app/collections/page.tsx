"use client";

import { useEffect, useState } from "react";
import { NFTCard } from "./_components";
import { OwnedNft } from "alchemy-sdk";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { alchemy } from "~~/services/alchemy";

const Collections: NextPage = () => {
  const { address } = useAccount();
  const [NFTs, setNFTs] = useState<OwnedNft[]>([]);

  const fetchNFTs = async () => {
    try {
      if (address !== undefined) {
        const nfts = await alchemy.nft.getNftsForOwner(address);
        if (nfts) {
          console.log("nfts:", nfts.ownedNfts);
          setNFTs(nfts.ownedNfts);
        }
      }
    } catch (error) {
      console.error("Error fetching data:", error);
    }
  };

  useEffect(() => {
    fetchNFTs();
  }, [fetchNFTs, address]);

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-5">
            {/* <span className="block text-2xl mb-2">My Collections</span> */}
            <span className="block text-4xl font-bold">My Collections:</span>
          </h1>
        </div>

        <div className="flex-grow bg-base-300 w-full mt-16 px-8 py-12">
          {NFTs.length === 0 ? (
            <h2 className="text-xl text-gray-200 flex justify-center">Loading...</h2>
          ) : (
            <div className="justify-items-center items-center gap-8 grid grid-cols-5">
              {NFTs.length &&
                NFTs.map((nft, index) => {
                  return <NFTCard nft={nft} key={index}></NFTCard>;
                })}
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default Collections;
