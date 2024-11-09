// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "src/contract/composable/ComposableSPGFactory.sol";
import "src/contract/interface/ISPGNFT.sol";

contract CreateComposableSPGProxy is Script {
    function run() external {
        // Load the deployer wallet private key and factory address from the .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address factoryAddress = vm.envAddress("COMPOSABLE_SPG_FACTORY_ADDRESS");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Instantiate the factory at the given address
        ComposableSPGFactory factory = ComposableSPGFactory(factoryAddress);

        // Set the parameters for the new ComposableSPG instance
        ISPGNFT.InitParams memory initParams = ISPGNFT.InitParams({
            name: "MyComposableSPG",
            symbol: "MCSPG",
            baseURI: "https://example.com/metadata/",
            contractURI: "https://example.com/contract-metadata",
            maxSupply: 10000,
            mintFee: 0.01 ether,
            mintFeeToken: 0xC0F6E387aC0B324Ec18EAcf22EE7271207dCE3d5, // Set to a token address if minting requires an ERC20 token
            mintFeeRecipient: 0x369Abe773328A9Aa2bb48B0D6F7D4bca58959EAb, // Replace with actual recipient address
            owner: 0x369Abe773328A9Aa2bb48B0D6F7D4bca58959EAb, // Set the contract owner as the transaction sender
            mintOpen: true,
            isPublicMinting: true
        });

        // Use the factory to create a new instance of ComposableSPG
        address proxyAddress = factory.createComposableSPG(initParams);

        // Log the new proxy address
        console.log("ComposableSPG instance deployed at:", proxyAddress);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
