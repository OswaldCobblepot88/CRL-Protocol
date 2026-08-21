// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVariableDebtToken {
    function mint(address user, uint256 amount, uint256 index) external returns (bool);
    function burn(address user, uint256 amount, uint256 index) external;
    function balanceOf(address user) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract VariableDebtToken is IVariableDebtToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    address public immutable POOL;
    address public immutable UNDERLYING_ASSET_ADDRESS;

    constructor(
        address pool,
        address underlyingAssetAddress,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) {
        POOL = pool;
        UNDERLYING_ASSET_ADDRESS = underlyingAssetAddress;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
    }

    function mint(address user, uint256 amount, uint256 index) external override returns (bool) {
        require(msg.sender == POOL, "VDT: Caller must be lending pool");
        _mint(user, amount);
        return true;
    }

    function burn(address user, uint256 amount, uint256 index) external override {
        require(msg.sender == POOL, "VDT: Caller must be lending pool");
        _burn(user, amount);
    }

    function balanceOf(address user) public view override returns (uint256) {
        return _balances[user];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _burn(address account, uint256 amount) internal {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "VDT: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
    }
}