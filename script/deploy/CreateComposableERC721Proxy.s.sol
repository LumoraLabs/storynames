// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "src/contract/composable/ComposableERC721Factory.sol";

contract CreateComposableERC721Proxy is Script {
    function run() external {
        // Load the deployer wallet private key and factory address from the .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address factoryAddress = vm.envAddress("COMPOSABLE_FACTORY_ADDRESS");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Instantiate the factory at the given address
        ComposableERC721Factory factory = ComposableERC721Factory(factoryAddress);

        // Set the parameters for the new ComposableERC721 instance
        string memory name = "MyComposableNFT";
        string memory symbol = "MCNFT";
        string memory contractURI = "https://example.com/metadata.json";
        address owner = tx.origin; // Set the contract owner as the sender

        // Use the factory to create a new instance of ComposableERC721
        address proxyAddress = factory.createComposableERC721(name, symbol, contractURI, owner);

        // Log the new proxy address
        console.log("ComposableERC721 instance deployed at:", proxyAddress);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
