// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LendingPoolStorage} from "./LendingPoolStorage.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {AToken} from "./tokenization/AToken.sol";
import {VariableDebtToken} from "./tokenization/VariableDebtToken.sol";
import {WadRayMath} from "../libraries/WadRayMath.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Configuration} from "../libraries/Configuration.sol";

contract LendingPool is LendingPoolStorage, ILendingPool {
    using WadRayMath for uint256;

    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    constructor(address provider) {
        _addressesProvider = provider;
    }

    function setConfigurator(address configurator) external {
        require(msg.sender == _addressesProvider, "LP: Caller not admin");
        _configurator = configurator;
    }

    function setPriceOracle(address oracle) external {
        require(msg.sender == _addressesProvider, "LP: Caller not admin");
        _priceOracle = oracle;
    }

    function initReserve(
        address asset,
        address aTokenAddress,
        address variableDebtTokenAddress,
        address interestRateStrategyAddress
    ) external {
        require(msg.sender == _configurator || msg.sender == _addressesProvider, "LP: Caller not configurator");
        
        DataTypes.ReserveData storage reserve = _reserves[asset];
        require(reserve.aTokenAddress == address(0), "LP: Reserve already initialized");

        reserve.aTokenAddress = aTokenAddress;
        reserve.variableDebtTokenAddress = variableDebtTokenAddress;
        reserve.interestRateStrategyAddress = interestRateStrategyAddress;
        reserve.liquidityIndex = 1e27;
        reserve.variableBorrowIndex = 1e27;
        reserve.lastUpdateTimestamp = uint40(block.timestamp);

        _reservesList.push(asset);
        _reservesCount++;
    }

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external override {
        DataTypes.ReserveData storage reserve = _reserves[asset];
        _updateState(reserve);
        _updateInterestRates(asset, reserve, amount, 0);

        require(
            IERC20(asset).transferFrom(msg.sender, address(this), amount),
            "LP: Transfer failed"
        );

        AToken(reserve.aTokenAddress).mint(onBehalfOf, amount, reserve.liquidityIndex);
    }

    function withdraw(address asset, uint256 amount, address to) external override returns (uint256) {
        DataTypes.ReserveData storage reserve = _reserves[asset];
        _updateState(reserve);

        uint256 userBalance = IERC20(reserve.aTokenAddress).balanceOf(msg.sender);
        uint256 amountToWithdraw = amount == type(uint256).max ? userBalance : amount;

        require(amountToWithdraw <= userBalance, "LP: Insufficient balance");

        _updateInterestRates(asset, reserve, 0, 0);
        AToken(reserve.aTokenAddress).burn(msg.sender, to, amountToWithdraw, reserve.liquidityIndex);

        require(
            IERC20(asset).transfer(to, amountToWithdraw),
            "LP: Transfer failed"
        );

        return amountToWithdraw;
    }

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external override {
        DataTypes.ReserveData storage reserve = _reserves[asset];
        _updateState(reserve);
        _updateInterestRates(asset, reserve, 0, amount);

        VariableDebtToken(reserve.variableDebtTokenAddress).mint(onBehalfOf, amount, reserve.variableBorrowIndex);

        require(
            IERC20(asset).transfer(onBehalfOf, amount),
            "LP: Transfer failed"
        );
    }

    function repay(address asset, uint256 amount, address onBehalfOf) external override returns (uint256) {
        DataTypes.ReserveData storage reserve = _reserves[asset];
        _updateState(reserve);

        uint256 variableDebt = IERC20(reserve.variableDebtTokenAddress).balanceOf(onBehalfOf);
        uint256 paybackAmount = amount == type(uint256).max ? variableDebt : amount;

        require(paybackAmount <= variableDebt, "LP: Amount exceeds debt");

        VariableDebtToken(reserve.variableDebtTokenAddress).burn(onBehalfOf, paybackAmount, reserve.variableBorrowIndex);

        require(
            IERC20(asset).transferFrom(msg.sender, address(this), paybackAmount),
            "LP: Transfer failed"
        );

        _updateInterestRates(asset, reserve, 0, 0);

        return paybackAmount;
    }

    function _updateState(DataTypes.ReserveData storage reserve) internal {
        if (reserve.lastUpdateTimestamp == block.timestamp) {
            return;
        }

        uint256 liquidityRate = reserve.currentLiquidityRate;
        uint256 totalDebt = IERC20(reserve.variableDebtTokenAddress).totalSupply();

        if (liquidityRate > 0) {
            uint256 cumulatedLiquidityInterest = _calculateLinearInterest(liquidityRate, uint40(block.timestamp - reserve.lastUpdateTimestamp));
            reserve.liquidityIndex = cumulatedLiquidityInterest.rayMul(reserve.liquidityIndex);
        }

        if (totalDebt > 0) {
            uint256 cumulatedVariableBorrowInterest = _calculateLinearInterest(reserve.currentVariableBorrowRate, uint40(block.timestamp - reserve.lastUpdateTimestamp));
            reserve.variableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(reserve.variableBorrowIndex);
        }

        reserve.lastUpdateTimestamp = uint40(block.timestamp);
    }

    function _updateInterestRates(
        address asset,
        DataTypes.ReserveData storage reserve,
        uint256 liquidityAdded,
        uint256 debtAdded
    ) internal {
        uint256 totalDebt = IERC20(reserve.variableDebtTokenAddress).totalSupply() + debtAdded;
        uint256 availableLiquidity = IERC20(asset).balanceOf(address(this)) + liquidityAdded;

        (uint256 currentLiquidityRate, uint256 currentVariableBorrowRate) = IInterestRateModel(
            reserve.interestRateStrategyAddress
        ).calculateInterestRates(asset, availableLiquidity, totalDebt, 0);

        reserve.currentLiquidityRate = currentLiquidityRate;
        reserve.currentVariableBorrowRate = currentVariableBorrowRate;

        emit ReserveDataUpdated(
            asset,
            currentLiquidityRate,
            currentVariableBorrowRate,
            reserve.liquidityIndex,
            reserve.variableBorrowIndex
        );
    }

    function _calculateLinearInterest(uint256 rate, uint40 timeDelta) internal view returns (uint256) {
        uint256 timeDeltaInYears = (uint256(timeDelta) * WadRayMath.RAY) / 365 days;
        return (rate.rayMul(timeDeltaInYears) + WadRayMath.RAY);
    }

    function getReserveData(address asset) external view override returns (DataTypes.ReserveData memory) {
        return _reserves[asset];
    }

    function getUserAccountData(address user) external view override returns (
        uint256 totalCollateralETH, 
        uint256 totalDebtETH, 
        uint256 availableBorrowsETH, 
        uint256 currentLiquidationThreshold, 
        uint256 ltv, 
        uint256 healthFactor
    ) {
        return (0, 0, 0, 0, 0, 0);
    }
}