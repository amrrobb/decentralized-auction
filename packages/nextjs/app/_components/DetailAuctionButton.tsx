import React from "react";
import Link from "next/link";

interface DynamicLinkButton {
  collection: string;
  tokenId: string;
}

export const DetailAuctionButton: React.FC<DynamicLinkButton> = ({ collection, tokenId }) => {
  // Construct the dynamic path
  const dynamicPath = `/detail/${collection}/${tokenId}/`;

  return (
    <Link href={dynamicPath} passHref legacyBehavior>
      <button className=" text-white font-semibold rounded-lg bg-sky-500/75 hover:bg-sky-500/50 px-5 py-2 mt-5">
        Go to Details
      </button>
    </Link>
  );
};

export default DynamicLinkButton;
