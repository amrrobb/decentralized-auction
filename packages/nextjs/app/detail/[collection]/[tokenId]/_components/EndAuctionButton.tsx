import React from "react";
import { useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

interface DynamicLinkButton {
  collection: string;
  tokenId: string;
}

export const EndAuctionButton: React.FC<DynamicLinkButton> = ({ collection, tokenId }) => {
  const { writeAsync: endAuction } = useScaffoldContractWrite({
    contractName: "DecentralizedAuction",
    functionName: "endAuction",
    args: [collection, BigInt(tokenId)],
  });

  return (
    <button
      onClick={async () => {
        await endAuction();
      }}
      className=" text-white font-semibold rounded-lg bg-sky-500/75 hover:bg-sky-500/50 px-5 py-2"
    >
      End Auction
    </button>
  );
};
