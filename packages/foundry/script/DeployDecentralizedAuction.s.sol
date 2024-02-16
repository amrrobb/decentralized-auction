//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DecentralizedAuction} from "../contracts/DecentralizedAuction.sol";
import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";
import {console} from "forge-std/console.sol";

contract DeployDecentralizedAuctionScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() public returns (DecentralizedAuction decentralizedAuction) {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        vm.startBroadcast(deployerPrivateKey);
        decentralizedAuction = new DecentralizedAuction(
            vm.addr(deployerPrivateKey)
        );

        console.logString(
            string.concat("DecentralizedAuction deployed at: ", vm.toString(address(decentralizedAuction)))
        );
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
