import { SetStateAction, useEffect, useState } from "react";
import Image from "next/image";
import { parseEther } from "viem";
import { EtherInput, InputBase } from "~~/components/scaffold-eth";
import { useDeployedContractInfo, useScaffoldContractRead, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

interface NFTCardProps {
  nft: any; // Use 'any' if 'nft' can be of any type
}

export const AuctionModalForm: React.FC<NFTCardProps> = ({ nft }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [startingPrice, setStartingPrice] = useState("");
  const [duration, setDuration] = useState("");
  const [collection, setCollection] = useState<string>(nft.contract.address);
  const [tokenId, setTokenId] = useState(nft.tokenId);
  const [isApproved, setIsApproved] = useState(false);

  const { writeAsync: createAuction } = useScaffoldContractWrite({
    contractName: "DecentralizedAuction",
    functionName: "createAuction",
    args: [collection, tokenId, parseEther(startingPrice), BigInt(duration)],
  });

  const { data: deAuctionContractData } = useDeployedContractInfo("DecentralizedAuction");
  const { writeAsync: approveCollection } = useScaffoldContractWrite({
    contractName: "ERC721",
    functionName: "approve",
    contractAddress: collection,
    args: [deAuctionContractData?.address, tokenId],
  });

  const { data: getApprovedCollection } = useScaffoldContractRead({
    contractName: "ERC721",
    functionName: "getApproved",
    contractAddress: collection,
    args: [tokenId],
  });

  useEffect(() => {
    if (checkApproved()) {
      setIsApproved(true);
    }
  }, [deAuctionContractData, getApprovedCollection]);

  const openModal = () => {
    setIsOpen(true);
  };

  const closeModal = () => {
    setIsOpen(false);
    setDuration("");
    setStartingPrice("");
  };

  const checkApproved = () => {
    return getApprovedCollection === deAuctionContractData?.address;
  };

  const handleDropdownChange = (event: { target: { value: SetStateAction<string> } }) => {
    setDuration(event.target.value);
  };

  const handleApproval = async (e: { stopPropagation: () => void }) => {
    e.stopPropagation();
    if (!isApproved) {
      await approveCollection();
    }
    if (checkApproved()) {
      setIsApproved(true);
    }
  };

  const handleSubmit = async (e: { preventDefault: () => void }) => {
    e.preventDefault();

    if (isApproved) {
      await createAuction();
    }
    closeModal();
  };

  return (
    <div>
      <button
        onClick={openModal}
        className=" text-white font-bold rounded-lg bg-sky-500/75 hover:bg-sky-500/50 px-5 py-2"
      >
        Auction
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
              <Image
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
                <label>Starting price: </label>
                <div className="w-3/5">
                  <EtherInput value={startingPrice} placeholder="ETH" onChange={amount => setStartingPrice(amount)} />
                </div>
              </div>
              <div className="flex justify-between items-center">
                <label htmlFor="dropdown">Select duration:</label>
                <div className="flex border-2 border-base-300 bg-base-200 rounded-full text-accent w-3/5">
                  <select
                    id="dropdown"
                    value={duration}
                    onChange={handleDropdownChange}
                    className="input input-ghost focus-within:border-transparent focus:outline-none focus:bg-transparent focus:text-gray-400 h-[2.2rem] min-h-[2.2rem] px-4 border w-full font-medium placeholder:text-accent/50 text-gray-400 "
                  >
                    <option value={""}>Choose duration </option>
                    <option selected value={60}>
                      1 Minute
                    </option>
                    <option value={600}>10 Minute</option>
                    <option value={3600}>1 Hour</option>
                    <option value={3600 * 24}>1 Day</option>
                    {/* Add more options as needed */}
                  </select>
                </div>
              </div>

              <div className="flex justify-center items-center mt-8 mb-2">
                {isApproved ? (
                  <button
                    disabled={!isApproved}
                    type="submit"
                    className="bg-sky-500/75 hover:bg-sky-500/50 text-white font-bold py-2 px-4 rounded mr-4"
                  >
                    Submit
                  </button>
                ) : (
                  <button
                    onClick={async e => {
                      await handleApproval(e);
                    }}
                    disabled={isApproved}
                    className="bg-sky-500/75 hover:bg-sky-500/50 text-white font-bold py-2 px-4 rounded mr-4"
                  >
                    Approve
                  </button>
                )}

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
