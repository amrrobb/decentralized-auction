import React from "react";
import { AuctionModalForm } from "./AuctionModalForm";
import { Address } from "~~/components/scaffold-eth";

interface NFTCardProps {
  nft: any; // Use 'any' if 'nft' can be of any type
  key: number;
}

export const NFTCard: React.FC<NFTCardProps> = ({ nft, key }) => {
  return (
    <>
      <div key={key} className="flex flex-col bg-base-200 text-center items-center rounded-xl pb-9">
        <div className="rounded-md">
          <img
            // width={400}
            // height={200}
            alt="nft-image-url"
            className="object-cover hover:object-contain h-48 w-96 rounded-t-xl"
            src={nft.image.cachedUrl || "./placeholder.png"}
          />
        </div>
        {/* <div className="flex flex-col y-gap-2 px-2 py-3 bg-slate-700 rounded-b-md h-110 "> */}
        <div className="justify-self-start mt-5">
          <b className=" text-xl text-gray-300">{nft.name || nft.contract.name}</b>
          <p className="text-l text-gray-200">
            {nft.contract.name} [#{nft.tokenId}]
          </p>
          <p className="text-gray-300">
            Collection: <Address address={nft.contract.address} />{" "}
          </p>
        </div>

        <AuctionModalForm nft={nft} />
      </div>
    </>
  );
};
