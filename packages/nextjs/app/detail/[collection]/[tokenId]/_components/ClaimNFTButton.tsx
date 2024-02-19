import React, { useState } from "react";
import { InputBase } from "~~/components/scaffold-eth";
import { useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

interface DynamicLinkButton {
  collection: string;
  tokenId: string;
}

export const ClaimNFTButton: React.FC<DynamicLinkButton> = ({ collection, tokenId }) => {
  const [isChecked, setIsChecked] = useState(false);
  const [receiver, setReceiver] = useState("");
  const [args, setArgs] = useState([collection, BigInt(tokenId)]);

  const { writeAsync: claimNft } = useScaffoldContractWrite({
    contractName: "DecentralizedAuction",
    functionName: "claimNft",
    args: args as never,
  });

  const handleCheckboxChange = () => {
    setIsChecked(!isChecked);
  };

  const handleClaimNFT = async (e: { preventDefault: () => void }) => {
    e.preventDefault();

    const newArgs = [collection, BigInt(tokenId)] as never;
    if (isChecked && receiver) {
      args.push(receiver as never);
    }
    setArgs(newArgs);

    await claimNft();
  };

  return (
    <>
      <div className="flex flex-col gap-5">
        <label>
          <input type="checkbox" checked={isChecked} onChange={handleCheckboxChange} />
          Claim to different Address
        </label>
        {isChecked && (
          <div>
            <div className="flex justify-between items-center">
              <label>Address: </label>
              <div className="">
                <InputBase value={receiver} onChange={setReceiver} />
              </div>
            </div>
          </div>
        )}
        <button
          onClick={async e => {
            await handleClaimNFT(e);
          }}
          className=" text-white font-bold rounded-lg bg-sky-500/75 hover:bg-sky-500/50 px-10 py-2"
        >
          Claim
        </button>
      </div>
    </>
  );
};

export default DynamicLinkButton;
