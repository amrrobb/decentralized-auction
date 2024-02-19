import { BidModalForm, ClaimNFTButton, EndAuctionButton } from ".";
import { formatEther } from "viem";
import { Address } from "~~/components/scaffold-eth";
import { getTimeLeft, isAddressZero } from "~~/utils/scaffold-eth/helper";

interface NftDetail {
  collection: string;
  tokenId: string;
  auction: any;
  nft: any;
}

export const NFTDetail: React.FC<NftDetail> = ({ collection, tokenId, auction, nft }) => {
  const checkAuction = () => {
    return !isAddressZero(auction!.seller);
  };

  const checkTimeOut = () => {
    const result = getTimeLeft(auction.endTime);
    return result === "passed";
  };

  const displayButtonComponent = () => {
    // Bid: there still time left for the auction
    if (auction && checkAuction() && !checkTimeOut()) {
      return <BidModalForm collection={collection} tokenId={tokenId} nft={nft} auction={auction} />;
    }
    // Ended: WHen time has passed but the ended status still false
    if (auction && checkAuction() && auction.ended === false) {
      return <EndAuctionButton collection={collection} tokenId={tokenId} />;
    }
    // Claim: When time has passed but the ended status true
    if (auction && checkAuction() && auction.ended === true) {
      return <ClaimNFTButton collection={collection} tokenId={tokenId} />;
    }
    return <p className="text-gray-300 text-xl font-bold">Claimed</p>;
  };

  const displayContent = () => {
    if (auction && checkAuction()) {
      return (
        <>
          <div className="flex justify-between items-center">
            <label className="text-gray-300">Seller: </label>
            <div>
              <Address address={auction?.seller} format="short" size="sm" />
            </div>
          </div>
          <div className="flex justify-between items-center">
            <label className="text-gray-300">Highest Bidder: </label>
            <div>
              <Address address={auction?.highestBidder} format="short" size="sm" />
            </div>
          </div>
          <div className="flex justify-between leading-none">
            <label className="text-gray-300">Starting Price: </label>
            <label className="text-gray-300">{auction ? formatEther(auction.startingPrice).toString() : 0} ETH</label>
          </div>
          <div className="flex justify-between leading-none">
            <label className="text-gray-300">Highest Bid: </label>
            <label className="text-gray-300">{auction ? formatEther(auction.highestBid).toString() : 0} ETH</label>
          </div>
        </>
      );
    }
  };

  return (
    <>
      <div className="flex flex-col bg-base-300 text-center items-center max-w-s rounded-xl pb-9 col-span-2">
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
          <div className="grid px-5 mt-5 gap-y-2">
            <div className="flex justify-between items-center">
              <label className="text-gray-300">Collection: </label>
              <div>
                <Address address={collection} format="short" size="sm" />
              </div>
            </div>

            {displayContent()}

            <div className="flex justify-between items-center">
              {auction && auction.endTime ? (
                <>
                  {checkTimeOut() ? (
                    <label className="text-gray-300 font-semibold text-lg mx-auto">Time has passed </label>
                  ) : (
                    <>
                      <label className="text-gray-300">Time left: </label>
                      <label className="text-gray-300">{getTimeLeft(auction!.endTime)}</label>
                    </>
                  )}
                </>
              ) : (
                <></>
              )}
            </div>
          </div>
        </div>
        <div className="flex justify-between items-center pt-5">{displayButtonComponent()}</div>
      </div>
    </>
  );
};
