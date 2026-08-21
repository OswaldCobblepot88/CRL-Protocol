// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {CredoraAddressesProvider} from "../src/CredoraAddressesProvider.sol";
import {LendingPool} from "../src/protocol/LendingPool.sol";
import {LendingPoolConfigurator} from "../src/protocol/LendingPoolConfigurator.sol";
import {DefaultReserveInterestRateStrategy} from "../src/protocol/DefaultReserveInterestRateStrategy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract DeployCore is Script {
    function run() external {
        vm.startBroadcast();

        CredoraAddressesProvider provider = new CredoraAddressesProvider();
        console.log("CredoraAddressesProvider:", address(provider));

        LendingPool pool = new LendingPool(address(provider));
        console.log("LendingPool:", address(pool));

        LendingPoolConfigurator configurator = new LendingPoolConfigurator(address(provider), address(pool));
        console.log("LendingPoolConfigurator:", address(configurator));

        provider.setLendingPool(address(pool));
        provider.setConfigurator(address(configurator));
        pool.setConfigurator(address(configurator));

        uint256 optimalUtilization = 0.8e27;
        uint256 baseBorrowRate = 0.02e27;
        uint256 slope1 = 0.04e27;
        uint256 slope2 = 0.75e27;

        DefaultReserveInterestRateStrategy rateStrategy = new DefaultReserveInterestRateStrategy(
            optimalUtilization,
            baseBorrowRate,
            slope1,
            slope2
        );
        console.log("DefaultReserveInterestRateStrategy:", address(rateStrategy));

        MockERC20 mockToken = new MockERC20("Mock USD", "MUSD", 18, 1000000 * 1e18);
        console.log("MockERC20:", address(mockToken));

        configurator.initReserve(
            address(mockToken),
            "Credora Mock USD",
            "aMUSD",
            "Credora Variable Debt MUSD",
            "vdMUSD",
            18,
            address(rateStrategy)
        );

        vm.stopBroadcast();
    }
}