// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "src/contract/composable/ComposableERC721Factory.sol";

contract DeployComposableERC721Factory is Script {
    function run() external {
        // Load the deployer wallet private key from the .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the ComposableERC721Factory contract
        ComposableERC721Factory factory = new ComposableERC721Factory();

        // Log the deployed factory contract address
        console.log("ComposableERC721Factory deployed at:", address(factory));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
