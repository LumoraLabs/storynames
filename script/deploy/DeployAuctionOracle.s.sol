// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {StablePriceOracle} from "src/contract/StablePriceOracle.sol";
import {LaunchAuctionPriceOracle} from "src/contract/LaunchAuctionPriceOracle.sol";

contract DeployAuctionPriceOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256[] memory prices = new uint256[](6);
        prices[0] = 316_808_781_402;
        prices[1] = 316_808_781_402;
        prices[2] = 31_680_878_140;
        prices[3] = 3_168_087_814;
        prices[4] = 316_808_781;
        prices[5] = 31_680_878; // 3,168,808.781402895 = 1e14 / (365.25 * 24 * 3600)
        uint256 premiumStart = 10000 ether;
        uint256 totalHours = 192 hours;

        StablePriceOracle oracle = new LaunchAuctionPriceOracle(prices, premiumStart, totalHours);
        console.log("Price Oracle deployed to:");
        console.log(address(oracle));

        vm.stopBroadcast();
    }
}
