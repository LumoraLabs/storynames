// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {StablePriceOracle} from "src/contract/StablePriceOracle.sol";
import {ExponentialPremiumPriceOracle} from "src/contract/ExponentialPremiumPriceOracle.sol";

contract DeployPriceOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256[] memory prices = new uint256[](6);
        prices[0] = 316_808_781_402;
        prices[1] = 316_808_781_402;
        prices[2] = 158_548_959_918;
        prices[3] = 15_854_895_991;
        prices[4] = 9_512_937_594;
        prices[5] = 6_512_937_594; // 3,168,808.781402895 = 1e14 / (365.25 * 24 * 3600)
        uint256 premiumStart = 10000 ether;
        uint256 totalDays = 8 days;

        StablePriceOracle oracle = new ExponentialPremiumPriceOracle(prices, premiumStart, totalDays);
        console.log("Price Oracle deployed to:");
        console.log(address(oracle));

        vm.stopBroadcast();
    }
}
