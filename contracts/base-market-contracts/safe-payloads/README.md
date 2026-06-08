# Base AI Cluster Safe Payloads

Generated for Base chain ID 8453.

## Files

- `01-deploy-base-ai-irms.json`: Safe Transaction Builder payload that deploys six new Kink IRMs through `0x2d94C898a17f9D8c0bA75010A51cd61BF55b402E`.
- `02-update-base-ai-params.json`: Safe Transaction Builder payload that updates caps, max liquidation discounts, LTVs, and vault IRM pointers.

## Critical Execution Order

1. Before importing `01-deploy-base-ai-irms.json`, confirm the IRM factory nonce is still `112`:

   ```sh
   cast nonce 0x2d94C898a17f9D8c0bA75010A51cd61BF55b402E --rpc-url "$RPC_URL_BASE"
   ```

2. Execute `01-deploy-base-ai-irms.json` from the Safe.
3. Verify the six deployed IRMs exactly match the predicted addresses and parameters below.
4. Only then import and execute `02-update-base-ai-params.json`.

If the factory nonce is not `112` before step 1, regenerate these payloads before using the update JSON.

## Expected IRMs

| Asset | Expected IRM | Curve |
|---|---|---|
| USDC | `0x8b304DEBB377Fb620A7A1f30373fbc0Bced92235` | 0/10/120/90 |
| WETH | `0xDCB187e27B17De035051377Cd388D80681BA724a` | 0/5/120/90 |
| VVV | `0xa54a6D20FAdDC6D014D1782085cD46A999FBfeC6` | 0/12/120/90 |
| VIRTUAL | `0x1633Bbf9e830B9D8857ec585F72b725edbf76394` | 0/12/120/90 |
| ZRO | `0xB270276C558e28c082CC9d68c76EFc3B15584336` | 0/10/120/90 |
| AERO | `0x944D26f3Fa9D642B5570CCa5583466a80aa7Ce6F` | 0/16/120/90 |

## Verification Commands

Replace `<IRM>` with each expected IRM address:

```sh
cast call <IRM> 'baseRate()(uint256)' --rpc-url "$RPC_URL_BASE"
cast call <IRM> 'slope1()(uint256)' --rpc-url "$RPC_URL_BASE"
cast call <IRM> 'slope2()(uint256)' --rpc-url "$RPC_URL_BASE"
cast call <IRM> 'kink()(uint32)' --rpc-url "$RPC_URL_BASE"
```

Expected IRM constants:

| Asset | baseRate | slope1 | slope2 | kink |
|---|---:|---:|---:|---:|
| USDC | 0 | 781343251 | 51141157152 | 3865470566 |
| WETH | 0 | 399976852 | 54573454741 | 3865470566 |
| VVV | 0 | 929057149 | 49811732071 | 3865470566 |
| VIRTUAL | 0 | 929057149 | 49811732071 | 3865470566 |
| ZRO | 0 | 781343251 | 51141157152 | 3865470566 |
| AERO | 0 | 1216732257 | 47222656100 | 3865470566 |

## Vault Updates

Governor multisig: `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C`

Caps:

| Asset | Supply Cap Encoded | Borrow Cap Encoded | Human Target |
|---|---:|---:|---|
| USDC | 79 | 79 | 10,000,000 USDC |
| WETH | 3542 | 3542 | 5,500 WETH |
| VVV | 2136 | 1112 | 330,000 supply / 170,000 borrow VVV |
| VIRTUAL | 2137 | 14424 | 3,300,000 supply / 2,250,000 borrow VIRTUAL |
| ZRO | 2840 | 1752 | 440,000 supply / 270,000 borrow ZRO |
| AERO | 986 | 986 | 15,000,000 AERO |

Max liquidation discount:

| Asset | Encoded |
|---|---:|
| USDC | 1000 |
| WETH | 1000 |
| VVV | 1500 |
| VIRTUAL | 1500 |
| ZRO | 1500 |
| AERO | 1500 |

LTV policy:

- USDC borrow / WETH collateral and WETH borrow / USDC collateral: 87% borrow LTV, 90% liquidation LTV.
- Any USDC or WETH borrow vault with volatile collateral: 80% borrow LTV, 85% liquidation LTV.
- Any volatile borrow vault with USDC or WETH collateral: 80% borrow LTV, 85% liquidation LTV.
- Volatile-to-volatile pairs remain disabled and are not included in the update payload.
