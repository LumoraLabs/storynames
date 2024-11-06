// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {RegistrarController} from "src/contract/RegistrarController.sol";
import {StoryRegistrar} from "src/contract/StoryRegistrar.sol";
import {TextResolver} from "src/contract/StoryResolver.sol";
import "src/util/Constants.sol";
import "ens-contracts/utils/NameEncoder.sol";
import "solady/utils/LibString.sol";

interface AddrResolver {
    function setAddr(bytes32 node, address addr) external;
}

contract RegisterNewName is Script {
    // NAME AND RECORD DEFS /////////////////////////////
    string NAME = "hellen";
    uint256 duration = 365 days;
    address RESOLVED_ADDR = 0x369Abe773328A9Aa2bb48B0D6F7D4bca58959EAb;
    //bytes32 discountKey = keccak256("testnet.discount.validator");
    string textKey = "bio";
    string textValue = "welcome to Story Name Service";
    /////////////////////////////////////////////////////

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address controllerAddr = vm.envAddress("REGISTRAR_CONTROLLER_ADDR");
        RegistrarController controller = RegistrarController(controllerAddr);
        address resolverAddr = vm.envAddress("STORY_RESOLVER_ADDR"); // Story Resolver

        RegistrarController.RegisterRequest memory request = RegistrarController.RegisterRequest({
            name: NAME,
            owner: RESOLVED_ADDR,
            duration: duration,
            resolver: resolverAddr,
            data: _packResolverData(),
            reverseRecord: true
        });

        controller.register{value: 9990881717616000}(request);

        vm.stopBroadcast();
    }

    function _packResolverData() internal view returns (bytes[] memory) {
        (, bytes32 rootNode) = NameEncoder.dnsEncodeName("ip");
        bytes32 label = keccak256(bytes(NAME));
        bytes32 nodehash = keccak256(abi.encodePacked(rootNode, label));

        bytes memory addrData = abi.encodeWithSelector(AddrResolver.setAddr.selector, nodehash, RESOLVED_ADDR);
        bytes memory textData = abi.encodeWithSelector(TextResolver.setText.selector, nodehash, textKey, textValue);
        bytes[] memory data = new bytes[](2);
        data[0] = addrData;
        data[1] = textData;
        return data;
    }
}
