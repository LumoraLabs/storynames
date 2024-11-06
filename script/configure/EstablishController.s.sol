// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {StoryRegistrar} from "src/contract/StoryRegistrar.sol";
import {ReverseRegistrar} from "src/contract/ReverseRegistrar.sol";

contract EstablishController is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address base = vm.envAddress("STORY_REGISTRAR_ADDR");
        address controller = vm.envAddress("REGISTRAR_CONTROLLER_ADDR");
        StoryRegistrar(base).addController(controller);

        address reverse = vm.envAddress("REVERSE_REGISTRAR_ADDR");
        ReverseRegistrar(reverse).setControllerApproval(controller, true);
        vm.stopBroadcast();
    }
}
