// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library DataTypes {
    struct ReserveData {
        uint256 liquidityIndex;
        uint256 variableBorrowIndex;
        uint256 currentLiquidityRate;
        uint256 currentVariableBorrowRate;
        uint40 lastUpdateTimestamp;
        address aTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint8 tier;
    }
}