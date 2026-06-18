// TEMPORARY: Hide collateral vaults during redeployment.
// Old vaults: wrong BPT addresses, hidden as safety net.
// New vaults: correct BPTs, hidden pending testing. Remove after Step 2F.
export const HIDDEN_COLLATERAL_VAULTS = new Set([
  '0xf18f3bc9440ad7940e6e2a86fd0c724add2dd0aa', // Beefy Pool 1 wrapper collateral — hidden pending testing
  '0x578c60e6df60336be41b316fde74aa3e2a4e0ea5', // Old Kintsu (sMON/wnWMON) — wrong BPT
  '0x6660195421557bc6803e875466f99a764ae49ed7', // Old Fastlane (shMON/wnWMON) — wrong BPT
  '0x175831af06c30f2ea5ea1e3f5eba207735eb9f92', // Old AZND (wnLOAZND/AZND/wnAUSD) — wrong BPT
])
