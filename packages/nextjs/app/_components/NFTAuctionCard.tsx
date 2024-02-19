import React from "react";
import { DetailAuctionButton } from "./DetailAuctionButton";
import { formatEther } from "viem";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldContractRead } from "~~/hooks/scaffold-eth";
import { checkTimeOut, getTimeLeft, isAddressZero } from "~~/utils/scaffold-eth/helper";

interface NFTCardProps {
  key: number;
  eventArgs: any;
  nft: any;
  isCreated?: boolean;
}

export const NFTAuctionCard: React.FC<NFTCardProps> = ({ key, eventArgs, nft, isCreated = true }) => {
  const { data: dataAuction } = useScaffoldContractRead({
    contractName: "DecentralizedAuction",
    functionName: "getAuction",
    args: [eventArgs.nftContract, BigInt(eventArgs.tokenId)],
  });

  const displayCard = () => {
    console.log(dataAuction, "auction");
    if (isCreated && isAddressZero(dataAuction![0])) {
      return false;
    } else {
      return true;
    }
  };

  return (
    <>
      {dataAuction && displayCard() ? (
        <>
          <div key={key} className="flex flex-col bg-base-200 text-center items-center justify-center rounded-xl pb-9">
            <div className="rounded-md">
              <div>
                <img
                  // loading="lazy"
                  // width={400}
                  // height={200}
                  alt="nft-image-url"
                  className="object-cover hover:object-contain h-48 w-96 rounded-t-xl"
                  src={nft?.image?.cachedUrl || "./placeholder.png"}
                />
              </div>

              <div className="mt-3">
                <p className="font-bold text-xl text-gray-300">{nft?.name || nft?.contract?.name}</p>
                <p className="text-l text-gray-200">
                  {nft?.contract?.name} [#{nft?.tokenId}]
                </p>
              </div>

              <div className="grid px-5 mt-5 gap-y-2">
                <div className="flex justify-between items-center">
                  <label className="text-gray-300">Seller: </label>
                  <div>
                    <Address address={eventArgs.seller} format="short" size="sm" />
                  </div>
                </div>
                <div className="flex justify-between items-center">
                  <label className="text-gray-300">Collection: </label>
                  <div>
                    <Address address={eventArgs.nftContract} format="short" size="sm" />
                  </div>
                </div>
                {isCreated ? (
                  <div className="flex justify-between items-center h-10 mb-5">
                    {" "}
                    {checkTimeOut(eventArgs.endTime!) ? (
                      <label className="text-gray-300 font-semibold text-lg mx-auto">Time has passed </label>
                    ) : (
                      <>
                        <label className="text-gray-300">Time left: </label>
                        <p className="text-gray-300">{getTimeLeft(eventArgs.endTime!)}</p>
                      </>
                    )}
                  </div>
                ) : (
                  <>
                    {eventArgs.success === false ? (
                      <>
                        <p className="font-semibold text-lg text-gray-300">There is no bidder</p>
                      </>
                    ) : (
                      <>
                        <div className="flex justify-between items-center">
                          <label className="text-gray-300">Highest Bidder: </label>
                          <div>
                            <Address address={eventArgs.highestBidder} format="short" size="sm" />
                          </div>
                        </div>
                        <div className="flex justify-between items-center">
                          <label className="text-gray-300">Highest Bid: </label>
                          <label className="text-gray-300">{formatEther(eventArgs.highestBid!).toString()}</label>
                        </div>
                      </>
                    )}
                  </>
                )}
              </div>
            </div>
            <DetailAuctionButton collection={eventArgs.nftContract} tokenId={eventArgs.tokenId} />
          </div>
        </>
      ) : (
        <></>
      )}
    </>
  );
};
