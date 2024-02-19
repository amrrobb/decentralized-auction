import { useState } from "react";
import { formatEther, parseEther } from "viem";
import { EtherInput, InputBase } from "~~/components/scaffold-eth";
import { useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

interface BidParams {
  tokenId: string;
  collection: string;
  auction: any;
  nft: any;
}

export const BidModalForm: React.FC<BidParams> = ({ auction, collection, nft, tokenId }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [bid, setBid] = useState("");
  const [, setCollection] = useState(collection);
  const [, setTokenId] = useState(tokenId);

  const { writeAsync: placeBid } = useScaffoldContractWrite({
    contractName: "DecentralizedAuction",
    functionName: "placeBid",
    value: parseEther(bid),
    args: [collection, BigInt(tokenId)],
  });

  const openModal = () => {
    setIsOpen(true);
  };

  const closeModal = () => {
    setIsOpen(false);
  };

  const displayPrice = () => {
    const price = auction.highestBid > 0 ? auction.highestBid : auction.startingPrice;
    return formatEther(price);
  };

  const handleSubmit = async (e: { preventDefault: () => void }) => {
    e.preventDefault();

    await placeBid();
    closeModal();
  };

  return (
    <div>
      <button
        onClick={openModal}
        className=" text-white font-bold rounded-lg bg-sky-500/75 hover:bg-sky-500/50 px-10 py-2"
      >
        Bid
      </button>
      {isOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 flex flex-col items-center justify-center"
          onClick={event => event.stopPropagation()}
        >
          <div className="bg-base-300 p-8 rounded-xl shadow-md w-2/5">
            <h2 className="text-2xl mb-4">Confirm Auction</h2>
            <div>
              <b className="m-0 text-xl text-gray-300">{nft.name || nft.contract.name}</b>
              <p className="m-0 text-l text-gray-200">{nft.contract.name || "\n"}</p>
            </div>
            <div className="rounded-md mb-8 mt-5">
              <img
                alt="nft-image-url"
                className="object-cover h-48 w-96 rounded-xl mx-auto"
                src={nft.image.cachedUrl || "./placeholder.png"}
              />
            </div>
            <form onSubmit={handleSubmit} className="grid gap-y-2">
              <div className="flex justify-between items-center">
                <label>Collection: </label>
                <div className="w-3/5">
                  <InputBase value={collection} disabled={true} onChange={setCollection} />
                </div>
              </div>
              <div className="flex justify-between items-center">
                <label>Token ID: </label>
                <div className="w-3/5">
                  <InputBase value={tokenId} disabled={true} onChange={setTokenId} />
                </div>
              </div>
              <div className="flex justify-between items-center">
                <label>Bid: </label>
                <div className="w-3/5">
                  <EtherInput
                    value={bid}
                    placeholder={`Input must be higher than ${displayPrice()} ETH`}
                    onChange={amount => setBid(amount)}
                  />
                </div>
              </div>

              <div className="flex justify-center items-center mt-8 mb-2">
                <button
                  type="submit"
                  className="bg-sky-500/75 hover:bg-sky-500/50 text-white font-bold py-2 px-4 rounded mr-4"
                >
                  Submit
                </button>

                <button
                  onClick={closeModal}
                  className="bg-gray-400 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded"
                >
                  Close
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
