// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {AttestationValidator} from "src/contract/discounts/AttestationValidator.sol";

contract DeployCB1DiscountValidator is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);
        address TRUSTED_SIGNER_ADDRESS = 0xB6944B3074F40959E1166fe010a3F86B02cF2b7c;
        bytes32 CB1_SCHEMA = 0xef8a28852c57170eafe8745aff8b47e22d36b8fb05476cc9ade66637974a1e8c;
        address INDEXER = 0xd147a19c3B085Fb9B0c15D2EAAFC6CB086ea849B;
        vm.startBroadcast(deployerPrivateKey);

        AttestationValidator validator =
            new AttestationValidator(deployerAddr, TRUSTED_SIGNER_ADDRESS, CB1_SCHEMA, INDEXER);
        console.log("Discount Validator deployed to:");
        console.log(address(validator));

        vm.stopBroadcast();
    }
}
