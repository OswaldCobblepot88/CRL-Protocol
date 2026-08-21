// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IInterestRateModel {
    function calculateInterestRates(
        address reserve,
        uint256 availableLiquidity,
        uint256 totalVariableDebt,
        uint256 reserveFactor
    ) external view returns (
        uint256 currentLiquidityRate,
        uint256 currentVariableBorrowRate
    );
}