// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CredoraAddressesProvider {
    address public owner;
    address public lendingPool;
    address public priceOracle;
    address public configurator;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setLendingPool(address _pool) external onlyOwner {
        lendingPool = _pool;
    }

    function setPriceOracle(address _oracle) external onlyOwner {
        priceOracle = _oracle;
    }

    function setConfigurator(address _configurator) external onlyOwner {
        configurator = _configurator;
    }
}