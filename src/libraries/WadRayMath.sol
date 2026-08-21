// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;
    
    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) { return RAY; }
    function wad() internal pure returns (uint256) { return WAD; }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b + HALF_RAY) / RAY;
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * RAY + HALF_RAY) / b;
    }
}