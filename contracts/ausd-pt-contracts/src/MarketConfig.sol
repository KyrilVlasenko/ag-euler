// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

library MarketConfig {
    uint256 internal constant CHAIN_ID = 143;

    address internal constant EVC = 0x7a9324E8f270413fa2E458f5831226d99C7477CD;
    address internal constant EVAULT_FACTORY = 0xba4Dd672062dE8FeeDb665DD4410658864483f1E;
    address internal constant KINK_IRM_FACTORY = 0x05Cccb5d0f1e1D568804453B82453a719Dc53758;
    address internal constant ORACLE_ROUTER_FACTORY = 0xdDA3cBC18e90606A83FBae6F798991af06dFA902;

    address internal constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address internal constant AUSD_PT = 0x9FC74f8Ed616B5BaF52a170caa97d6d3898602d1;
    address internal constant EARNAUSD_PT = 0xDaf216939826AcABA0C2312F7E30A890213845CD;

    address internal constant ROUTER = 0x481591F617161408b60ca6d6a00987019dB70ef6;
    address internal constant AUSD_PT_ADAPTER = 0xe2c2f533861E34df2f95B664a789583dBd194A74;
    address internal constant EARNAUSD_PT_ADAPTER = 0x10b69CBD942c6Add426525b443b7B8bD84F07C34;

    address internal constant GOVERNOR = 0x36639EA17c35A4639eaE371391497Cb3D02d120a;
    address internal constant FEE_RECEIVER = 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C;

    uint256 internal constant AUSD_PT_IRM_BASE = 0;
    uint256 internal constant AUSD_PT_IRM_SLOPE1 = 477_682_641;
    uint256 internal constant AUSD_PT_IRM_SLOPE2 = 25_616_515_386;
    uint32 internal constant AUSD_PT_IRM_KINK = 3_865_470_566;

    uint256 internal constant EARNAUSD_PT_IRM_BASE = 0;
    uint256 internal constant EARNAUSD_PT_IRM_SLOPE1 = 929_057_149;
    uint256 internal constant EARNAUSD_PT_IRM_SLOPE2 = 26_315_867_485;
    uint32 internal constant EARNAUSD_PT_IRM_KINK = 3_865_470_566;

    uint16 internal constant AUSD_PT_BORROW_LTV = 9_000;
    uint16 internal constant AUSD_PT_LIQUIDATION_LTV = 9_400;
    uint16 internal constant EARNAUSD_PT_BORROW_LTV = 8_800;
    uint16 internal constant EARNAUSD_PT_LIQUIDATION_LTV = 9_200;

    uint16 internal constant MAX_LIQUIDATION_DISCOUNT = 1_500;
    uint16 internal constant LIQUIDATION_COOL_OFF = 1;
    uint16 internal constant INTEREST_FEE = 1_000;

    // AmountCap: 600 * 10^12 / 100 = 6,000,000 * 10^6.
    uint16 internal constant AUSD_PT_SUPPLY_CAP = 38_412;
    // AmountCap: 250 * 10^12 / 100 = 2,500,000 * 10^6.
    uint16 internal constant EARNAUSD_PT_SUPPLY_CAP = 16_012;
    // Non-zero exponent with zero mantissa encodes an actual cap of zero.
    uint16 internal constant ZERO_CAP = 6;
}
