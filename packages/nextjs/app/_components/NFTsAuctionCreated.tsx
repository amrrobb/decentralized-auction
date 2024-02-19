"use client";

import { useEffect, useState } from "react";
import { NFTAuctionCard } from "./NFTAuctionCard";
import { Nft, NftMetadataBatchToken } from "alchemy-sdk";
import { useScaffoldEventHistory } from "~~/hooks/scaffold-eth";
import { alchemy } from "~~/services/alchemy";

export const NFTsAuctionCreated = () => {
  const [NFTMetadataBatch, setNFTMetadataBatch] = useState<NftMetadataBatchToken[]>([]);
  const [NFTs, setNFTs] = useState<Nft[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [liveEvents, setLiveEvents] = useState<any[]>([]);

  const { data: auctionCreatedEvents, isLoading: isACreatedEventsLoading } = useScaffoldEventHistory({
    contractName: "DecentralizedAuction",
    eventName: "AuctionCreated",
    fromBlock: 5299390n,
  });

  const fetchNFTs = async () => {
    try {
      if (NFTMetadataBatch.length) {
        const nfts = await alchemy.nft.getNftMetadataBatch(NFTMetadataBatch);
        if (nfts) {
          setNFTs(nfts.nfts);
        }
      }
    } catch (error) {
      console.error("Error fetching data:", error);
    }
  };

  useEffect(() => {
    if (!isLoading && auctionCreatedEvents && auctionCreatedEvents.length) {
      const duplicate: any = {};
      const liveEvents: any[] = [];
      const batch: NftMetadataBatchToken[] = [];
      auctionCreatedEvents?.map(async event => {
        const argCollection = event.args!.nftContract!;
        const argTokenId = String(event.args!.tokenId!);
        const key = `${argCollection}/${argTokenId}`;

        if (duplicate[key] === undefined) {
          duplicate[key] = 1;

          batch.push({
            contractAddress: argCollection,
            tokenId: argTokenId,
          });
          liveEvents.push(event);
        }
      });
      setLiveEvents(liveEvents);
      setNFTMetadataBatch(batch);
      setIsLoading(true);
    }
    if (isLoading) {
      fetchNFTs();
    }
  }, [isACreatedEventsLoading, auctionCreatedEvents, isLoading]);

  return (
    <>
      <div className="flex-grow bg-base-300 w-full mt-5 px-8 py-12">
        <h1 className="text-center mb-8">
          <span className="block font-semibold text-3xl mb-2">Live Auctions</span>
        </h1>
        {isACreatedEventsLoading ? (
          <h2 className="text-xl text-gray-200 flex justify-center">Loading...</h2>
        ) : (
          <>
            {!auctionCreatedEvents || auctionCreatedEvents.length === 0 || liveEvents.length === 0 ? (
              <h2 className="text-xl text-gray-200 flex justify-center">No events found</h2>
            ) : (
              <div className="justify-items-center items-center gap-8 grid grid-cols-5">
                {liveEvents?.map((event, index) => {
                  return <NFTAuctionCard key={index} eventArgs={event.args} nft={NFTs[index]}></NFTAuctionCard>;
                })}
              </div>
            )}
          </>
        )}
      </div>
    </>
  );
};
