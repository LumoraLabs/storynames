// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {IPriceOracle} from "src/contract/interface/IPriceOracle.sol";
import {StoryRegistrar} from "src/contract/StoryRegistrar.sol";
import {Registry} from "src/contract/Registry.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IReverseRegistrar} from "src/contract/interface/IReverseRegistrar.sol";
import {RegistrarController} from "src/contract/RegistrarController.sol";
import {NameEncoder} from "ens-contracts/utils/NameEncoder.sol";

import "src/util/Constants.sol";

contract DeployRegistrarController is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        address oracle = vm.envAddress("PRICE_ORACLE_ADDR");
        address reverse = vm.envAddress("REVERSE_REGISTRAR_ADDR"); // deployer-owned rev registrar
        address base = vm.envAddress("STORY_REGISTRAR_ADDR");
        (, bytes32 rootNode) = NameEncoder.dnsEncodeName("ip");
        string memory rootName = ".ip";

        RegistrarController controller = new RegistrarController(
            StoryRegistrar(base),
            IPriceOracle(oracle),
            IReverseRegistrar(reverse),
            deployerAddress,
            rootNode,
            rootName,
            deployerAddress
        );

        console.log("RegistrarController deployed to:");
        console.log(address(controller));

        vm.stopBroadcast();
    }
}
