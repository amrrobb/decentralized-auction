import { Alchemy, Network } from "alchemy-sdk";
import scaffoldConfig from "~~/scaffold.config";

const settings = {
  apiKey: scaffoldConfig.alchemyApiKey,
  network: Network.ETH_SEPOLIA,
};

export const alchemy = new Alchemy(settings);
