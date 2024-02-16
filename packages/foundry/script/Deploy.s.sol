//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";
import {DeployDecentralizedAuctionScript} from "./DeployDecentralizedAuction.s.sol";
import {NFTWithoutUri} from "../contracts/NFTWithoutUri.sol";
import {NFTWithUri} from "../contracts/NFTWithUri.sol";
import {console} from "forge-std/console.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() external {
        // Deploy DecentralizedAuction contract
        DeployDecentralizedAuctionScript decentralizedAuctionScript = new DeployDecentralizedAuctionScript();
        vm.allowCheatcodes(address(decentralizedAuctionScript));
        decentralizedAuctionScript.run();

        otherRun(address(decentralizedAuctionScript));
    }

    function getDeployerKey() internal returns (uint256 deployerPrivateKey) {
        deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
    }

    function otherRun(address _contract) internal {
        uint256 deployerPrivateKey = getDeployerKey();
        vm.startBroadcast(deployerPrivateKey);

        NFTWithoutUri contract1 = new NFTWithoutUri(
            _contract
        );

        NFTWithUri contract2 = new NFTWithUri();

        console.logString(string.concat("NFTWithoutUri contract deployed: ", vm.toString(address(contract1))));
        console.logString(string.concat("NFTWithUri contract deployed: ", vm.toString(address(contract2))));
        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    function test() public {}
}
