"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { BidHEventHistory, NFTDetail } from "./_components";
import { Nft } from "alchemy-sdk";
import type { NextPage } from "next";
import { useScaffoldContractRead } from "~~/hooks/scaffold-eth";
import { alchemy } from "~~/services/alchemy";

interface Auction {
  seller: string;
  highestBidder: string;
  startingPrice: string;
  highestBid: string;
  endTime: bigint;
  ended: boolean;
}

const Detail: NextPage = () => {
  const { collection, tokenId } = useParams<{ collection: string; tokenId: string }>();
  const [nft, setNft] = useState<Nft>();
  const [auction, setAuction] = useState<Auction>();

  const { data: getAuction, isLoading: isAuctionLoading } = useScaffoldContractRead({
    contractName: "DecentralizedAuction",
    functionName: "getAuction",
    args: [collection, BigInt(tokenId)],
  });

  const fetchNFT = async () => {
    try {
      const nft = await alchemy.nft.getNftMetadata(collection, tokenId);
      setNft(nft);
    } catch (error) {
      console.error("Error fetching data:", error);
    }
  };

  useEffect(() => {
    if (!nft) {
      fetchNFT();
    }
    if (getAuction) {
      setAuction({
        seller: getAuction[0],
        highestBidder: getAuction[1],
        startingPrice: getAuction[2].toString(),
        highestBid: getAuction[3].toString(),
        endTime: getAuction[4],
        ended: getAuction[5],
      });
    }
  }, [getAuction, isAuctionLoading]);

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Auction Detail</span>
            <span className="block text-4xl font-semibold">
              {nft?.contract?.name} [#{nft?.tokenId}]
            </span>
          </h1>
        </div>

        <div className="grid grid-cols-6 justify-items-center items-start gap-8">
          <NFTDetail auction={auction} collection={collection} nft={nft} tokenId={tokenId} />

          <BidHEventHistory tokenId={tokenId} collection={collection} />
        </div>
      </div>
    </>
  );
};

export default Detail;
