import { formatEther } from "viem";
import { Spinner } from "~~/components/Spinner";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldEventHistory } from "~~/hooks/scaffold-eth";

interface EventHistory {
  collection: string;
  tokenId: string;
}

export const BidHEventHistory: React.FC<EventHistory> = ({ collection, tokenId }) => {
  const { data: bidPlacedEvents, isLoading: isBidPlacedEventsLoading } = useScaffoldEventHistory({
    contractName: "DecentralizedAuction",
    eventName: "BidPlaced",
    fromBlock: 5299390n,
    filters: {
      nftContract: collection,
      tokenId: BigInt(tokenId),
    },
  });

  return (
    <>
      <div className="flex flex-col bg-base-300 px-10 py-10 text-center items-center max-w-4xl rounded-xl col-span-4 justify-self-stretch">
        <h2 className="text-gray-300 text-2xl font-bold">Auction Bid History</h2>
        {isBidPlacedEventsLoading ? (
          <div className="flex justify-center items-center mt-8">
            <Spinner width="65" height="65" />
          </div>
        ) : (
          <div className="flex flex-col text-left w-4/5 mb-10">
            <div className="overflow-x-auto sm:-mx-6 lg:-mx-8">
              <div className="inline-block min-w-full py-2 sm:px-6 lg:px-8">
                <div className="overflow-hidden">
                  <table className="min-w-full text-left text-sm font-light">
                    <thead className="border-b font-medium dark:border-neutral-500">
                      <tr>
                        <th scope="col" className="px-6 py-4">
                          #
                        </th>
                        <th scope="col" className="px-6 py-4">
                          Bidder
                        </th>
                        <th scope="col" className="px-6 py-4">
                          Last Bid
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {!bidPlacedEvents || bidPlacedEvents.length === 0 ? (
                        <tr>
                          <td colSpan={3} className="pt-5 text-lg text-center">
                            No events found
                          </td>
                        </tr>
                      ) : (
                        bidPlacedEvents?.map((event, index) => {
                          return (
                            <tr key={index} className="border-b dark:border-neutral-500">
                              <td className="whitespace-nowrap px-6 py-4 font-medium">{index + 1}</td>
                              <td className="whitespace-nowrap px-6 py-4 font-medium">
                                <Address address={event.args.bidder!} format="short" size="base" />
                              </td>
                              <td className="whitespace-nowrap px-6 py-4">{formatEther(event.args.bid!)}</td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
};
