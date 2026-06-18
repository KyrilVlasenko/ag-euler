#!/usr/bin/env node

const fs = require('fs')
const path = require('path')

const CHAIN_ID = '143'
const EULER_ROUTER = '0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73'
const AUSD_BORROW_VAULT = '0x438cedcE647491B1d93a73d491eC19A50194c222'
const BEEFY_WRAPPER = '0x6e58131ea11ed990d4b62476529cf2502fe0ec5f'
const BORROW_LTV = '9500'
const LIQUIDATION_LTV = '9600'
const RAMP_DURATION = '0'

function requireAddress(name) {
  const value = (process.env[name] || '').trim()
  if (!/^0x[a-fA-F0-9]{40}$/.test(value)) {
    throw new Error(`${name} must be a 20-byte hex address`)
  }
  return value
}

function govSetResolvedVaultTx(vault) {
  return {
    to: EULER_ROUTER,
    value: '0',
    data: null,
    contractMethod: {
      inputs: [
        { name: 'vault', type: 'address', internalType: 'address' },
        { name: 'resolved', type: 'bool', internalType: 'bool' },
      ],
      name: 'govSetResolvedVault',
      payable: false,
    },
    contractInputsValues: {
      vault,
      resolved: 'true',
    },
  }
}

function setLtvTx(collateral) {
  return {
    to: AUSD_BORROW_VAULT,
    value: '0',
    data: null,
    contractMethod: {
      inputs: [
        { name: 'collateral', type: 'address', internalType: 'address' },
        { name: 'borrowLTV', type: 'uint16', internalType: 'uint16' },
        { name: 'liquidationLTV', type: 'uint16', internalType: 'uint16' },
        { name: 'rampDuration', type: 'uint32', internalType: 'uint32' },
      ],
      name: 'setLTV',
      payable: false,
    },
    contractInputsValues: {
      collateral,
      borrowLTV: BORROW_LTV,
      liquidationLTV: LIQUIDATION_LTV,
      rampDuration: RAMP_DURATION,
    },
  }
}

function safeTx(name, description, transactions) {
  return {
    version: '1.0',
    chainId: CHAIN_ID,
    createdAt: Date.now(),
    meta: { name, description },
    transactions,
  }
}

function validatePayload(payload) {
  JSON.parse(JSON.stringify(payload))
}

function writeJson(fileName, payload, dryRun) {
  validatePayload(payload)
  const outPath = path.join(__dirname, fileName)
  if (dryRun) {
    console.log(`Validated ${outPath}`)
    return
  }
  fs.writeFileSync(outPath, `${JSON.stringify(payload, null, 2)}\n`)
  JSON.parse(fs.readFileSync(outPath, 'utf8'))
  console.log(`Wrote ${outPath}`)
}

function main() {
  const beefyCollateralVault = requireAddress('NEW_BEEFY_COLLATERAL_EVAULT')
  const dryRun = process.argv.includes('--dry-run')

  writeJson(
    'safe-tx-beefy-wire-router.json',
    safeTx(
      'Wire EulerRouter for Beefy wrapper collateral',
      'Resolve the Beefy collateral EVault to the Beefy wrapper, and resolve the Beefy wrapper to its Pool 1 BPT asset. No oracle config is added because Pool 1 BPT/AUSD is already configured.',
      [
        govSetResolvedVaultTx(beefyCollateralVault),
        govSetResolvedVaultTx(BEEFY_WRAPPER),
      ],
    ),
    dryRun,
  )

  writeJson(
    'safe-tx-beefy-add-ausd-ltv.json',
    safeTx(
      'Add Beefy wrapper collateral to AUSD borrow vault',
      'Set AUSD borrow vault LTVs for the Beefy wrapper collateral EVault at 95% borrow LTV and 96% liquidation LTV.',
      [setLtvTx(beefyCollateralVault)],
    ),
    dryRun,
  )
}

main()
