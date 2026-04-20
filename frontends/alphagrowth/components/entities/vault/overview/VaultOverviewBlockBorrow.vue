<script setup lang="ts">
import { formatNumber } from '~/utils/string-utils'
import { nanoToValue } from '~/utils/crypto-utils'
import type { Vault, SecuritizeVault } from '~/entities/vault'
import type { LTVRampConfig } from '~/entities/vault/ltv'
import { getCurrentLiquidationLTV, isLiquidationLTVRamping } from '~/entities/vault'
import { useModal } from '~/components/ui/composables/useModal'
import { useVaultRegistry } from '~/composables/useVaultRegistry'
import { HIDDEN_COLLATERAL_VAULTS } from '~/entities/hiddenCollateralVaults'
import { VaultRampDownModal } from '#components'

const modal = useModal()

const emits = defineEmits<{
  'vault-click': [address: string]
}>()
const { vault } = defineProps<{ vault: Vault }>()
const { get: registryGet } = useVaultRegistry()

const onCollateralClick = (address: string) => {
  emits('vault-click', address)
}

const onRampDownInfoIconClick = (event: MouseEvent, pair: LTVRampConfig) => {
  modal.open(VaultRampDownModal, {
    props: pair,
  })
}

// Build collateral pairs from collateralLTVs where currentLiquidationLTV > 0
// Excludes fully ramped-down collaterals (borrowLTV == 0) with no remaining supply
const allCollateralPairs = computed(() => {
  const pairs: Array<{
    collateral: Vault | SecuritizeVault
    borrowLTV: bigint
    liquidationLTV: bigint
    initialLiquidationLTV: bigint
    targetTimestamp: bigint
    rampDuration: bigint
  }> = []

  vault.collateralLTVs.forEach((ltv) => {
    if (getCurrentLiquidationLTV(ltv) <= 0n) return
    if (HIDDEN_COLLATERAL_VAULTS.has(ltv.collateral.toLowerCase())) return

    // Try to find the collateral vault from registry
    const collateralEntry = registryGet(ltv.collateral)
    if (collateralEntry) {
      const collateral = collateralEntry.vault as Vault | SecuritizeVault
      if (ltv.borrowLTV <= 0n && collateral.totalAssets <= 0n) return

      pairs.push({
        collateral,
        borrowLTV: ltv.borrowLTV,
        liquidationLTV: ltv.liquidationLTV,
        initialLiquidationLTV: ltv.initialLiquidationLTV,
        targetTimestamp: ltv.targetTimestamp,
        rampDuration: ltv.rampDuration,
      })
    }
  })

  // Sort by borrow LTV descending (highest first)
  return pairs.sort((a, b) => (b.borrowLTV > a.borrowLTV ? 1 : b.borrowLTV < a.borrowLTV ? -1 : 0))
})
</script>

<template>
  <div
    v-if="allCollateralPairs.length"
    class="bg-surface-secondary rounded-xl flex flex-col gap-24 p-24 shadow-card"
  >
    <div>
      <p class="text-h3 text-content-primary mb-12">
        Collateral exposure
      </p>
      <p class="text-content-secondary">
        Deposits in this vault can be borrowed.
        Please make sure you're comfortable accepting the collaterals
        listed in the table below before supplying.
      </p>
    </div>

    <div class="flex flex-col gap-12">
      <div
        v-for="pair in allCollateralPairs"
        :key="pair.collateral.address"
        class="bg-surface rounded-xl text-content-primary block no-underline cursor-pointer hover:bg-card-hover transition-colors shadow-sm"
        @click="onCollateralClick(pair.collateral.address)"
      >
        <div
          class="px-16 pt-16 pb-12 border-b border-line-subtle"
        >
          <VaultLabelsAndAssets
            :vault="pair.collateral"
            :assets="[pair.collateral.asset]"
          />
        </div>
        <div class="flex flex-col gap-12 px-16 pt-12 pb-16">
          <VaultOverviewLabelValue
            label="Max LTV"
            orientation="horizontal"
            :value="`${formatNumber(nanoToValue(pair.borrowLTV, 2), 2)}%`"
          />
          <VaultOverviewLabelValue
            orientation="horizontal"
          >
            <template #label>
              <span class="flex items-center gap-4">
                Liquidation LTV
                <SvgIcon
                  v-if="isLiquidationLTVRamping(pair)"
                  class="!w-20 !h-20 text-content-muted cursor-pointer hover:text-content-secondary"
                  name="info-circle"
                  @click.stop.prevent="onRampDownInfoIconClick($event, pair)"
                />
              </span>
            </template>
            <span class="flex items-center gap-4">
              <SvgIcon
                v-if="isLiquidationLTVRamping(pair)"
                name="arrow-top-right"
                class="!w-14 !h-14 text-warning-500 shrink-0 rotate-180 cursor-pointer"
                title="Liquidation LTV ramping down"
                @click.stop.prevent="onRampDownInfoIconClick($event, pair)"
              />
              {{ `${formatNumber(nanoToValue(getCurrentLiquidationLTV(pair), 2), 2)}%` }}
            </span>
          </VaultOverviewLabelValue>
        </div>
      </div>
    </div>
  </div>
</template>
