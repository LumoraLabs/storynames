// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "src/contract/composable/ComposableSPGFactory.sol";

contract DeployComposableSPGFactory is Script {
    // Iliad
    address constant DERIVATIVE_WORKFLOWS_ADDRESS = 0xa8815CEB96857FFb8f5F8ce920b1Ae6D70254C7B;
    address constant GROUPING_WORKFLOWS_ADDRESS = 0xcd754994eBE5Ce16D432C1f936f98ac0d4aABA0e;
    address constant LICENSE_ATTACHMENT_WORKFLOWS_ADDRESS = 0x44Bad1E4035a44eAC1606B222873E4a85E8b7D9c;
    address constant REGISTRATION_WORKFLOWS_ADDRESS = 0xde13Be395E1cd753471447Cf6A656979ef87881c;
    address constant STORYNAME_ADDRESS = 0x5cc93d8Ef014bDBa08297C181eF0480AFa163995;

    function run() external {
        // Load the deployer wallet private key from the .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the ComposableERC721Factory contract
        ComposableSPGFactory factory = new ComposableSPGFactory(
            DERIVATIVE_WORKFLOWS_ADDRESS,
            GROUPING_WORKFLOWS_ADDRESS,
            LICENSE_ATTACHMENT_WORKFLOWS_ADDRESS,
            REGISTRATION_WORKFLOWS_ADDRESS,
            STORYNAME_ADDRESS
        );

        // Log the deployed factory contract address
        console.log("ComposableSPGFactory deployed at:", address(factory));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
