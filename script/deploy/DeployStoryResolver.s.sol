// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";

import "src/contract/StoryResolver.sol";
import {Registry} from "src/contract/Registry.sol";
import "src/util/Constants.sol";

contract DeployStoryResolver is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        /// StoryResolver Resolver constructor data
        address ensAddress = vm.envAddress("REGISTRY_ADDR");
        address controller = vm.envAddress("REGISTRAR_CONTROLLER_ADDR"); // controller can set data on deployment
        address reverse = vm.envAddress("REVERSE_REGISTRAR_ADDR");

        StoryResolver resolver = new StoryResolver(Registry(ensAddress), controller, reverse, deployerAddress);

        console.log(address(resolver));

        vm.stopBroadcast();
    }
}
