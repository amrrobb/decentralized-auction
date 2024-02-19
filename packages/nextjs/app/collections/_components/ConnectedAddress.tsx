"use client";

import { formatEther } from "viem";
import { useAccount } from "wagmi";
import { useScaffoldContractRead, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

export const ConnectedAddress = () => {
  const { address: connectedAddress } = useAccount();

  const { data: balance } = useScaffoldContractRead({
    contractName: "DecentralizedAuction",
    functionName: "getBalance",
    args: [connectedAddress],
  });

  const { writeAsync: withdrawBalance } = useScaffoldContractWrite({
    contractName: "DecentralizedAuction",
    functionName: "withdrawBalance",
  });

  const handleWithdraw = async () => {
    await withdrawBalance();
  };

  return (
    <div className="bg-base-300 p-6 text-center rounded-lg max-w-md mx-auto mt-6">
      <h2 className="text-lg font-semibold mb-2">Balance: {balance ? formatEther(balance) : "0"} ETH</h2>

      <button
        onClick={async () => {
          await handleWithdraw();
        }}
        disabled={formatEther(balance!) === "0"}
        className=" text-white font-bold rounded-lg bg-sky-500/75 hover:bg-sky-500/50 px-10 py-2"
      >
        Withdraw
      </button>
    </div>
  );
};
