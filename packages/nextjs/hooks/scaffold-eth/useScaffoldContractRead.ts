import { useTargetNetwork } from "./useTargetNetwork";
import type { ExtractAbiFunctionNames } from "abitype";
import { useContractRead } from "wagmi";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import {
  AbiFunctionReturnType,
  ContractAbi,
  ContractAddress,
  ContractName,
  UseScaffoldReadConfig,
} from "~~/utils/scaffold-eth/contract";

/**
 * Wrapper around wagmi's useContractRead hook which automatically loads (by name) the contract ABI and address from
 * the contracts present in deployedContracts.ts & externalContracts.ts corresponding to targetNetworks configured in scaffold.config.ts
 * @param config - The config settings, including extra wagmi configuration
 * @param config.contractName - deployed contract name
 * @param config.contractAddress - custom contract address
 * @param config.functionName - name of the function to be called
 * @param config.args - args to be passed to the function call
 */
export const useScaffoldContractRead = <
  TContractName extends ContractName,
  TContractAddress extends ContractAddress,
  TFunctionName extends ExtractAbiFunctionNames<ContractAbi<TContractName>, "pure" | "view">,
>({
  contractName,
  contractAddress,
  functionName,
  args,
  ...readConfig
}: UseScaffoldReadConfig<TContractName, TContractAddress, TFunctionName>) => {
  const { data: deployedContract } = useDeployedContractInfo(contractName, contractAddress);
  const { targetNetwork } = useTargetNetwork();

  return useContractRead({
    chainId: targetNetwork.id,
    functionName,
    address: contractAddress || deployedContract?.address,
    abi: deployedContract?.abi,
    watch: true,
    args,
    enabled: !Array.isArray(args) || !args.some(arg => arg === undefined),
    ...(readConfig as any),
  }) as Omit<ReturnType<typeof useContractRead>, "data" | "refetch"> & {
    data: AbiFunctionReturnType<ContractAbi, TFunctionName> | undefined;
    refetch: (options?: {
      throwOnError: boolean;
      cancelRefetch: boolean;
    }) => Promise<AbiFunctionReturnType<ContractAbi, TFunctionName>>;
  };
};
