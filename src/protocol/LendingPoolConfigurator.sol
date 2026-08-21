// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LendingPool} from "./LendingPool.sol";
import {AToken} from "./tokenization/AToken.sol";
import {VariableDebtToken} from "./tokenization/VariableDebtToken.sol";

contract LendingPoolConfigurator {
    address public immutable ADDRESSES_PROVIDER;
    LendingPool public immutable POOL;

    modifier onlyPoolAdmin() {
        require(msg.sender == ADDRESSES_PROVIDER, "Caller is not pool admin");
        _;
    }

    constructor(address provider, address pool) {
        ADDRESSES_PROVIDER = provider;
        POOL = LendingPool(pool);
    }

    function initReserve(
        address asset,
        string memory aTokenName,
        string memory aTokenSymbol,
        string memory variableDebtTokenName,
        string memory variableDebtTokenSymbol,
        uint8 underlyingAssetDecimals,
        address interestRateStrategyAddress
    ) external onlyPoolAdmin {
        AToken aToken = new AToken(
            address(POOL),
            asset,
            aTokenName,
            aTokenSymbol,
            underlyingAssetDecimals
        );

        VariableDebtToken variableDebtToken = new VariableDebtToken(
            address(POOL),
            asset,
            variableDebtTokenName,
            variableDebtTokenSymbol,
            underlyingAssetDecimals
        );

        POOL.initReserve(
            asset,
            address(aToken),
            address(variableDebtToken),
            interestRateStrategyAddress
        );
    }
}