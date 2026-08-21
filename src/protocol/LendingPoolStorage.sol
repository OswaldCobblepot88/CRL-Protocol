// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DataTypes} from "../libraries/DataTypes.sol";

contract LendingPoolStorage {
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    mapping(address => DataTypes.ReserveData) internal _reserves;
    mapping(address => ReserveConfigurationMap) internal _reservesConfig;
    mapping(address => UserConfigurationMap) internal _usersConfig;
    
    address[] internal _reservesList;
    uint256 internal _reservesCount;
    
    address internal _addressesProvider;
    address internal _priceOracle;
    address internal _configurator;
}