// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "src/contract/EAStoryNameSBT.sol";

contract DeployEAStoryNameSBT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        /// SBT constructor data
        string memory name = "Story Name Early Tester SBT";
        string memory symbol = "StoryNS-SBT";
        string memory baseURI = "https://rose-occupational-bee-58.mypinata.cloud/ipfs/QmSEziDngJkxrLCrVFaBCSsZDiVWJkzNwxnaXdZ47GwY78";
        address owner = deployerAddress; 

        // Deploy the SBT contract
        EAStoryNameSBT sbt = new EAStoryNameSBT(name, symbol, baseURI, owner);
        console.log("Deployed SBT contract at address:", address(sbt));

        vm.stopBroadcast();
    }
}
