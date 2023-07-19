//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct Config {
        address priceFeed;
    }
    Config public currentConfig;

    uint8 public constant DECIMALS = 0;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) currentConfig = getSepoliaConfig();
        else if (block.chainid == 1) currentConfig = getMainnetConfig();
        else currentConfig = getOrCreateAnvilConfig();
    }

    function getSepoliaConfig() public pure returns (Config memory) {
        Config memory sepoliaConfig = Config({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetConfig() public pure returns (Config memory) {
        Config memory mainnetConfig = Config({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    function getOrCreateAnvilConfig() public returns (Config memory) {
        if (currentConfig.priceFeed != address(0)) return currentConfig;

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        Config memory anvilConfig = Config({
            priceFeed: (address(mockPriceFeed))
        });

        return anvilConfig;
    }
}
