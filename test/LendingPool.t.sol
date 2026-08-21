// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CredoraAddressesProvider} from "../src/CredoraAddressesProvider.sol";
import {LendingPool} from "../src/protocol/LendingPool.sol";
import {LendingPoolConfigurator} from "../src/protocol/LendingPoolConfigurator.sol";
import {DefaultReserveInterestRateStrategy} from "../src/protocol/DefaultReserveInterestRateStrategy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract LendingPoolTest is Test {
    CredoraAddressesProvider provider;
    LendingPool pool;
    LendingPoolConfigurator configurator;
    DefaultReserveInterestRateStrategy rateStrategy;
    MockERC20 token;

    address user = address(0x1);
    address borrower = address(0x2);

    function setUp() public {
        provider = new CredoraAddressesProvider();
        pool = new LendingPool(address(provider));
        configurator = new LendingPoolConfigurator(address(provider), address(pool));

        provider.setLendingPool(address(pool));
        provider.setConfigurator(address(configurator));
        
        vm.prank(address(provider));
        pool.setConfigurator(address(configurator));

        rateStrategy = new DefaultReserveInterestRateStrategy(0.8e27, 0.02e27, 0.04e27, 0.75e27);
        token = new MockERC20("Mock USD", "MUSD", 18, 1000000 * 1e18);

        vm.startPrank(address(provider));
        configurator.initReserve(
            address(token),
            "Credora Mock USD",
            "aMUSD",
            "Credora Variable Debt MUSD",
            "vdMUSD",
            18,
            address(rateStrategy)
        );
        vm.stopPrank();

        token.transfer(user, 10000 * 1e18);
        token.transfer(borrower, 10000 * 1e18);
    }

    function testDeposit() public {
        vm.startPrank(user);
        token.approve(address(pool), 1000 * 1e18);

        pool.deposit(address(token), 1000 * 1e18, user, 0);

        address aTokenAddress = pool.getReserveData(address(token)).aTokenAddress;
        assertEq(IERC20(aTokenAddress).balanceOf(user), 1000 * 1e18);
        assertEq(token.balanceOf(address(pool)), 1000 * 1e18);
        vm.stopPrank();
    }

    function testBorrow() public {
        vm.startPrank(user);
        token.approve(address(pool), 10000 * 1e18);
        pool.deposit(address(token), 10000 * 1e18, user, 0);
        vm.stopPrank();

        vm.startPrank(borrower);
        token.approve(address(pool), 5000 * 1e18);
        pool.deposit(address(token), 5000 * 1e18, borrower, 0);

        pool.borrow(address(token), 1000 * 1e18, 2, 0, borrower);

        address debtTokenAddress = pool.getReserveData(address(token)).variableDebtTokenAddress;
        assertEq(IERC20(debtTokenAddress).balanceOf(borrower), 1000 * 1e18);
        assertEq(token.balanceOf(borrower), 6000 * 1e18);
        vm.stopPrank();
    }

    function testRepay() public {
        testBorrow();

        vm.startPrank(borrower);
        token.approve(address(pool), 2000 * 1e18);

        pool.repay(address(token), type(uint256).max, borrower);

        address debtTokenAddress = pool.getReserveData(address(token)).variableDebtTokenAddress;
        assertEq(IERC20(debtTokenAddress).balanceOf(borrower), 0);
        vm.stopPrank();
    }
}