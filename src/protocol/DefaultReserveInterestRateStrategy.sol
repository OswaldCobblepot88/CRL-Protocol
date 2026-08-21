// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";
import {WadRayMath} from "../libraries/WadRayMath.sol";

contract DefaultReserveInterestRateStrategy is IInterestRateModel {
    using WadRayMath for uint256;

    uint256 public immutable OPTIMAL_UTILIZATION_RATE;
    uint256 public immutable BASE_VARIABLE_BORROW_RATE;
    uint256 public immutable VARIABLE_RATE_SLOPE_1;
    uint256 public immutable VARIABLE_RATE_SLOPE_2;
    uint256 public immutable MAX_BORROW_RATE;

    constructor(
        uint256 optimalUtilizationRate,
        uint256 baseVariableBorrowRate,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2
    ) {
        OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
        BASE_VARIABLE_BORROW_RATE = baseVariableBorrowRate;
        VARIABLE_RATE_SLOPE_1 = variableRateSlope1;
        VARIABLE_RATE_SLOPE_2 = variableRateSlope2;
        MAX_BORROW_RATE = baseVariableBorrowRate + variableRateSlope1 + variableRateSlope2;
    }

    function calculateInterestRates(
        address,
        uint256 availableLiquidity,
        uint256 totalVariableDebt,
        uint256 reserveFactor
    ) external view override returns (uint256 currentLiquidityRate, uint256 currentVariableBorrowRate) {
        uint256 totalDebt = totalVariableDebt;

        if (totalDebt == 0 && availableLiquidity == 0) {
            return (0, BASE_VARIABLE_BORROW_RATE);
        }

        uint256 totalLiquidity = availableLiquidity + totalDebt;
        uint256 utilizationRate = (totalDebt == 0 && availableLiquidity == 0)
            ? 0
            : totalDebt.rayDiv(totalLiquidity);

        if (utilizationRate < OPTIMAL_UTILIZATION_RATE) {
            currentVariableBorrowRate = BASE_VARIABLE_BORROW_RATE +
                utilizationRate.rayMul(VARIABLE_RATE_SLOPE_1).rayDiv(OPTIMAL_UTILIZATION_RATE);
        } else {
            uint256 excessUtilizationRateRatio = (utilizationRate - OPTIMAL_UTILIZATION_RATE).rayDiv(
                WadRayMath.RAY - OPTIMAL_UTILIZATION_RATE
            );

            currentVariableBorrowRate = BASE_VARIABLE_BORROW_RATE +
                VARIABLE_RATE_SLOPE_1 +
                excessUtilizationRateRatio.rayMul(VARIABLE_RATE_SLOPE_2);
        }

        currentLiquidityRate = currentVariableBorrowRate.rayMul(utilizationRate).rayMul(
            WadRayMath.RAY - reserveFactor
        );
    }
}