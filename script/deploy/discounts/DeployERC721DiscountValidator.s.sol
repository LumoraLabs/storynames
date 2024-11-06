// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {ERC721DiscountValidator} from "src/contract/discounts/ERC721DiscountValidator.sol";
import {MockERC1155} from "test/mocks/MockERC1155.sol";

contract DeployERC721DiscountValidator is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        address token = 0x5cc93d8Ef014bDBa08297C181eF0480AFa163995;
        console.log("ERC721 token address:");
        console.log(token);

        ERC721DiscountValidator validator = new ERC721DiscountValidator(address(token));

        console.log("Discount Validator deployed to:");
        console.log(address(validator));

        vm.stopBroadcast();
    }
}
