// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Addresses} from "../Addresses.sol";

library ST0xAddresses {
    address internal constant EVC = Addresses.EVC;
    address internal constant EVAULT_FACTORY = Addresses.EVAULT_FACTORY;
    address internal constant KINK_IRM_FACTORY = Addresses.KINK_IRM_FACTORY;
    address internal constant USDC = Addresses.USDC;
    address internal constant USD = Addresses.USD;

    address internal constant SHARED_ROUTER = 0xc0A9A8cdafb7490476F11ef85d1208434b59f3C8;
    address internal constant SAFE_MULTISIG = 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C;
    address internal constant EXISTING_USDC_VAULT = 0x4C1aeda9B43EfcF1da1d1755b18802aAbe90f61E;

    address internal constant DIA_ORACLE = 0xCE521b52513242c5094bc56f57887BB2A05B8129;

    address internal constant WT_SPYM = 0x31C2C14134e6E3B7ef9478297F199331133Fc2d8;
    address internal constant WT_MSTR = 0xFF05E1bD696900dc6A52CA35Ca61Bb1024eDa8e2;
    address internal constant WT_COIN = 0x5cDa0E1CA4ce2af96315f7F8963C85399c172204;
}
