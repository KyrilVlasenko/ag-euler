# AlphaGrowth AUSD PT Cluster — Monad Deployment

Deployed and verified on Monad (chain 143) on June 20, 2026. Governance was transferred to the AlphaGrowth multisig.

## Contracts

| Component | Address |
|---|---|
| AUSD / AUSD-PT borrow vault | `0x248C74aA002A571c340a3d894aAF294884A49bE1` |
| AUSD-PT collateral vault | `0xf3E55a17c4c59Cb70EA44973795fA8F3c3BAad72` |
| AUSD / earnAUSD-PT borrow vault | `0x7cc566d100E81a9708fd23B18F6B92D3249430C9` |
| earnAUSD-PT collateral vault | `0xC4fAbE0B5A280163aB47E3162689A278C81df3f9` |
| AUSD / AUSD-PT KinkIRM | `0x12EE3Ab7C093B0428B6a1Fe4c1e2A68840e1dcCE` |
| AUSD / earnAUSD-PT KinkIRM | `0x94bD8a224Ff5d664edC0D150576f6B13605D1125` |
| Shared Euler router | `0x481591F617161408b60ca6d6a00987019dB70ef6` |
| AUSD-PT adapter | `0xe2c2f533861E34df2f95B664a789583dBd194A74` |
| earnAUSD-PT adapter | `0x10b69CBD942c6Add426525b443b7B8bD84F07C34` |
| Governor | `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C` |
| Fee receiver | `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C` |

## Final Parameters

| Parameter | AUSD / AUSD-PT | AUSD / earnAUSD-PT |
|---|---:|---:|
| Borrow LTV | 90% | 88% |
| Liquidation LTV | 94% | 92% |
| Maximum liquidation discount | 15% | 15% |
| Liquidation cool-off | 1 second | 1 second |
| Interest fee | 10% | 10% |
| AUSD supply cap | Unlimited | Unlimited |
| AUSD borrow cap | Unlimited | Unlimited |
| PT supply cap | 6,000,000 PT | 2,500,000 PT |
| PT borrow cap | 0 | 0 |
| IRM | 0% / 6% at 90% / 50% max | 0% / 12% at 90% / 60% max |

The two borrow vaults each have exactly one LTV-listed collateral vault. No cross-market LTV is configured.

## Transactions

All 28 transactions returned status `1 (success)`.

### IRMs

- AUSD-PT IRM: [`0x742677af...099a6`](https://monadscan.com/tx/0x742677af2c8861a2ae3bf7631b3250ba462fb286a0bb08d924c2d44d788099a6)
- earnAUSD-PT IRM: [`0xa1b528f7...3988`](https://monadscan.com/tx/0xa1b528f772dd85eeaec33298afc9b666cbb6c9fac177126da3d0cb370b173988)

### Vaults

- AUSD-PT borrow vault: [`0x87d0cc06...88b8`](https://monadscan.com/tx/0x87d0cc0626fca68ea9cf5f59cabb9fb69f8c15128910206b696072e7095388b8)
- AUSD-PT collateral vault: [`0xd44fbdcc...6552`](https://monadscan.com/tx/0xd44fbdcccdc3b3322c1d67f569e9e9e682ca8c127728b11ecf742847975d6552)
- earnAUSD-PT borrow vault: [`0x7e1cbe8f...1d1a`](https://monadscan.com/tx/0x7e1cbe8fa71548bd96a303b18cb9687c3dcb48238663f3ecc99824f03e6d1d1a)
- earnAUSD-PT collateral vault: [`0x35c63f15...4833`](https://monadscan.com/tx/0x35c63f15224397004065477cf43b5b0eb3f365d4b40250973435a0a47d9d4833)

### Router Resolution

- Resolve AUSD-PT collateral vault: [`0xac65d642...dd45`](https://monadscan.com/tx/0xac65d64245e06918e27d40341c15b68a35790d0abae0c06ef7e5cac39ecedd45)
- Resolve earnAUSD-PT collateral vault: [`0x34bbb825...46b4`](https://monadscan.com/tx/0x34bbb825af8d7d701250e1a6423c3bf18b92b20507a338ab257ef5590cb846b4)

### AUSD / AUSD-PT Configuration

- Set IRM: [`0xd9286bba...d4d9`](https://monadscan.com/tx/0xd9286bba4b6df34d91ca266b7264962be4b8e10b45220c2d6cf6f11c480dd4d9)
- Set maximum liquidation discount: [`0x44063c98...242e`](https://monadscan.com/tx/0x44063c989709c023b66e0582328b43fb437d405337466d227ebb89171de6242e)
- Set liquidation cool-off: [`0x4886105f...ffe7`](https://monadscan.com/tx/0x4886105f6336b75ae6e8285a349e970d8ca83b9bd4ea100ee3dabc6e6ba5ffe7)
- Set interest fee: [`0xf2ef52b4...0f11`](https://monadscan.com/tx/0xf2ef52b473588afb767adeb8e836708f76070f71d82e543a3e6be22fd8af0f11)
- Set fee receiver: [`0x62431882...c7b8`](https://monadscan.com/tx/0x6243188299da38517d40501bcf6d2a4c0c5c7580d6f629b4025de5f80b1bc7b8)
- Set AUSD caps: [`0xeedd87b2...2e30`](https://monadscan.com/tx/0xeedd87b26b105b170efd4be02b46cd661111b01ce52b6a85852251e3dfc62e30)
- Set LTV: [`0x0ec64643...d284`](https://monadscan.com/tx/0x0ec646430645fe963be0622f637fc0d8b57d22592b6bbadae461c4da2e71d284)
- Set PT caps: [`0x93c8a818...1cc0`](https://monadscan.com/tx/0x93c8a818bebf31152f4f6a6f91a9b05fae70fe885f1e2fd83bdb693833711cc0)

### AUSD / earnAUSD-PT Configuration

- Set IRM: [`0xa2107c2b...f7b9`](https://monadscan.com/tx/0xa2107c2bc2f6a384e73265676364c9751d2755a34e0469acb142391dadb6f7b9)
- Set maximum liquidation discount: [`0x155f47e1...799f`](https://monadscan.com/tx/0x155f47e11fbee4d9dcc48ac544b2e28c88df0ba51057c6d72f99048576b9799f)
- Set liquidation cool-off: [`0x2f174c28...72af`](https://monadscan.com/tx/0x2f174c2858543b25e4a40577e6d7776f686064b16220c9d4a924211c457272af)
- Set interest fee: [`0x68a1e09d...48dc`](https://monadscan.com/tx/0x68a1e09d4228d281d1663d8e34ea5925e64301bddddec3fa8ce833d9cc6e48dc)
- Set fee receiver: [`0x9bb9892b...0d2a`](https://monadscan.com/tx/0x9bb9892b34f880fb73689f98142574f3753c32a14b9fb617d79d1753b4340d2a)
- Set AUSD caps: [`0xb7fadb4f...c3a7`](https://monadscan.com/tx/0xb7fadb4f195d4716bbe5696f409160285d2eadf34bafe2a8c1ff0a57de8cc3a7)
- Set LTV: [`0xf4f06889...0d76`](https://monadscan.com/tx/0xf4f068895a1786fbb4e95a89a8ff4a9ad8330f7bc133d147819970660baa0d76)
- Set PT caps: [`0x27c2b1e7...c883`](https://monadscan.com/tx/0x27c2b1e729eb2a0526ee23c8a9bf78ce4691180815ddb06441dd29830b1dc883)

### Activation

- AUSD-PT borrow vault: [`0xf8e8d255...cea2`](https://monadscan.com/tx/0xf8e8d2550045ecb7dc51c4dcf4be51dd52efa292bdaf222862a0944976e3cea2)
- AUSD-PT collateral vault: [`0x6626aec8...474d`](https://monadscan.com/tx/0x6626aec8e2f965faf5a3aff7f2874aaa2f7f290726efa6b28c410a059057474d)
- earnAUSD-PT borrow vault: [`0x61ccc549...5ef0`](https://monadscan.com/tx/0x61ccc549285735469f7c0421e376d1744886fbe24c986e261b4cdfd6da0f5ef0)
- earnAUSD-PT collateral vault: [`0x358273a4...6f0c`](https://monadscan.com/tx/0x358273a40d79bb980bdbc804e36f4b5129c1581116807fef16868287bfe66f0c)

## Verification

- Production scripts completed with sequential `--slow` broadcasting.
- Fork tests passed for deposit, borrow, repay, withdrawal, cap decoding, and cross-market rejection.
- Live verification returned:
  - AUSD-PT collateral-vault share quote: `0.976797 AUSD`
  - earnAUSD-PT collateral-vault share quote: `0.959081 AUSD`
  - `DEPLOYMENT_VERIFIED=true`
- Deployer nonce advanced from 7 to 35, matching 28 successful transactions.

## Governance Transfer

All four vaults and the shared router are governed by `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C`.

- AUSD-PT borrow vault: [`0xde663de3...9db9`](https://monadscan.com/tx/0xde663de38e0480644d5b615384c30eb9b40658a25c08bb2de59f6adf492c9db9)
- AUSD-PT collateral vault: [`0x3833ca81...f8a0`](https://monadscan.com/tx/0x3833ca81d3070638ef6d76064be78ee58367be5b0a8289819909f055c550f8a0)
- earnAUSD-PT borrow vault: [`0xdc754e12...15f1`](https://monadscan.com/tx/0xdc754e1212380b2a2f871fbcdb223994a8dd50b0c4e0562ecb67ad29896215f1)
- earnAUSD-PT collateral vault: [`0xc36c327e...1806`](https://monadscan.com/tx/0xc36c327e22b5f9f6c0b5ec1c64ea0903f086f62442e9ccb7b8c840e91d101806)

## Labels Handoff

No labels files were modified. Merge the following entry into Monad `products.json`:

```json
{
  "alphagrowth-ausd-pt-cluster": {
    "name": "AlphaGrowth AUSD PT Cluster",
    "description": "Borrow AUSD against isolated Pendle AUSD and earnAUSD principal-token collateral on Monad. Curated by Alpha Growth.",
    "entity": [
      "alphagrowth",
      "euler"
    ],
    "url": "https://alphagrowth.io",
    "vaults": [
      "0x248C74aA002A571c340a3d894aAF294884A49bE1",
      "0xf3E55a17c4c59Cb70EA44973795fA8F3c3BAad72",
      "0x7cc566d100E81a9708fd23B18F6B92D3249430C9",
      "0xC4fAbE0B5A280163aB47E3162689A278C81df3f9"
    ]
  }
}
```

Merge these entries into Monad `vaults.json`:

```json
{
  "0x248C74aA002A571c340a3d894aAF294884A49bE1": {
    "name": "AUSD / AUSD-PT Borrow Vault",
    "description": "Lend or borrow AUSD against PT-AUSD-8OCT2026 collateral.",
    "entity": "alphagrowth"
  },
  "0xf3E55a17c4c59Cb70EA44973795fA8F3c3BAad72": {
    "name": "PT-AUSD-8OCT2026 Collateral Vault",
    "description": "Isolated Pendle AUSD principal-token collateral vault.",
    "entity": "alphagrowth"
  },
  "0x7cc566d100E81a9708fd23B18F6B92D3249430C9": {
    "name": "AUSD / earnAUSD-PT Borrow Vault",
    "description": "Lend or borrow AUSD against PT-earnAUSD-8OCT2026 collateral.",
    "entity": "alphagrowth"
  },
  "0xC4fAbE0B5A280163aB47E3162689A278C81df3f9": {
    "name": "PT-earnAUSD-8OCT2026 Collateral Vault",
    "description": "Isolated Pendle earnAUSD principal-token collateral vault.",
    "entity": "alphagrowth"
  }
}
```

For local frontend testing while governance remains with the development wallet, add this address to `entities.json` under `alphagrowth.addresses`:

```json
"0x36639EA17c35A4639eaE371391497Cb3D02d120a": "AlphaGrowth AUSD PT Dev Governor"
```

Without that temporary entity mapping, the frontend may display the risk manager or vault type as unknown.
