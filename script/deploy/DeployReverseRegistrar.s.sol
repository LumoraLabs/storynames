// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {Registry} from "src/contract/Registry.sol";
import {ReverseRegistrar} from "src/contract/ReverseRegistrar.sol";
import "src/util/Constants.sol";

contract DeployReverseRegistrar is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        address ensAddress = vm.envAddress("REGISTRY_ADDR"); // deployer-owned registry
        Registry registry = Registry(ensAddress);

        ReverseRegistrar revRegstrar = new ReverseRegistrar(
            Registry(ensAddress),
            deployerAddress, // deployer as owner
            ADDR_REVERSE_NODE
        );

        // establish the reverse registrar as the owner of the 'addr.reverse' node
        bytes32 reverseLabel = keccak256("reverse");
        bytes32 storyReverseLabel = keccak256("addr");
        registry.setSubnodeOwner(0x0, reverseLabel, deployerAddress);
        registry.setSubnodeOwner(REVERSE_NODE, storyReverseLabel, address(revRegstrar));

        console.log(address(revRegstrar));

        vm.stopBroadcast();
    }
}
