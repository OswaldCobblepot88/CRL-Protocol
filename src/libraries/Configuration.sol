// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Configuration {
    uint256 internal constant LTV_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000;
    uint256 internal constant LIQUIDATION_THRESHOLD_MASK = 0x000000000000000000000000000000000000000000000000000000000000FFFF; 
    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;

    function setLtv(uint256 self, uint256 ltv) internal pure returns (uint256) {
        return self & LTV_MASK | ltv;
    }

    function getLtv(uint256 self) internal pure returns (uint256) {
        return self & ~LTV_MASK;
    }

    function setLiquidationThreshold(uint256 self, uint256 threshold) internal pure returns (uint256) {
        return self & LIQUIDATION_THRESHOLD_MASK | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    function getLiquidationThreshold(uint256 self) internal pure returns (uint256) {
        return (self & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    function isUsingAsCollateral(uint256 self, uint256 reserveIndex) internal pure returns (bool) {
        return (self >> (reserveIndex * 2)) & 1 != 0;
    }

    function isBorrowing(uint256 self, uint256 reserveIndex) internal pure returns (bool) {
        return (self >> (reserveIndex * 2 + 1)) & 1 != 0;
    }
}