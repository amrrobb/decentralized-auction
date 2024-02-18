"use client";

import { useAccount } from "wagmi";
import { Address } from "~~/components/scaffold-eth";

export const ConnectedAddress = () => {
  const { address: connectedAddress } = useAccount();

  return (
    <div className="bg-base-300 p-6 rounded-lg max-w-md mx-auto mt-6">
      <h2 className="text-lg font-bold mb-2">My Collections</h2>

      <div className="text-sm font-semibold mb-2">
        <Address address={connectedAddress} />
      </div>

      <div className="text-sm font-semibold">{/* Balance: <Balance address={connectedAddress} /> */}</div>
    </div>
  );
};
