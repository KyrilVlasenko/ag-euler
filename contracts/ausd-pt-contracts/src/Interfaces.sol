// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

interface IKinkIRMFactory {
    function deploy(uint256 baseRate, uint256 slope1, uint256 slope2, uint32 kink)
        external
        returns (address);
    function isValidDeployment(address deployment) external view returns (bool);
}

interface IEVaultFactory {
    function createProxy(address implementation, bool upgradeable, bytes calldata trailingData)
        external
        returns (address);
}

interface IEulerRouter {
    function governor() external view returns (address);
    function getConfiguredOracle(address base, address quote) external view returns (address);
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256);
    function resolvedVaults(address vault) external view returns (address);
    function govSetResolvedVault(address vault, bool set) external;
}

interface IEulerRouterFactory {
    function isValidDeployment(address deployment) external view returns (bool);
}

interface IEVault {
    function deposit(uint256 amount, address receiver) external returns (uint256);
    function withdraw(uint256 amount, address receiver, address owner) external returns (uint256);
    function borrow(uint256 amount, address receiver) external returns (uint256);
    function repay(uint256 amount, address receiver) external returns (uint256);
    function asset() external view returns (address);
    function oracle() external view returns (address);
    function unitOfAccount() external view returns (address);
    function governorAdmin() external view returns (address);
    function interestRateModel() external view returns (address);
    function feeReceiver() external view returns (address);
    function interestFee() external view returns (uint16);
    function caps() external view returns (uint16 supplyCap, uint16 borrowCap);
    function LTVBorrow(address collateral) external view returns (uint16);
    function LTVLiquidation(address collateral) external view returns (uint16);
    function LTVList() external view returns (address[] memory);
    function maxLiquidationDiscount() external view returns (uint16);
    function liquidationCoolOffTime() external view returns (uint16);
    function hookConfig() external view returns (address hookTarget, uint32 hookedOps);

    function setInterestRateModel(address irm) external;
    function setGovernorAdmin(address governor) external;
    function setMaxLiquidationDiscount(uint16 discount) external;
    function setLiquidationCoolOffTime(uint16 coolOffTime) external;
    function setInterestFee(uint16 fee) external;
    function setFeeReceiver(address receiver) external;
    function setCaps(uint16 supplyCap, uint16 borrowCap) external;
    function setLTV(address collateral, uint16 borrowLTV, uint16 liquidationLTV, uint32 rampDuration)
        external;
    function setHookConfig(address hookTarget, uint32 hookedOps) external;
}

interface IEVC {
    function enableCollateral(address account, address vault) external payable;
    function enableController(address account, address vault) external payable;
    function disableController(address account) external payable;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address receiver, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IIRMLinearKink {
    function baseRate() external view returns (uint256);
    function slope1() external view returns (uint256);
    function slope2() external view returns (uint256);
    function kink() external view returns (uint256);
}
