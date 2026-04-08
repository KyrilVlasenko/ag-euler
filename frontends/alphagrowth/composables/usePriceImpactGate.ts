import { unref } from 'vue'
import type { Ref, ComputedRef } from 'vue'
import { useModal } from '~/components/ui/composables/useModal'
import { HighPriceImpactModal } from '#components'
import { isPriceImpactDanger } from '~/utils/priceImpact'

export const usePriceImpactGate = (options: {
  directPriceImpact: Ref<number | null> | ComputedRef<number | null>
  multipliedPriceImpact?: Ref<number | null> | ComputedRef<number | null>
}) => {
  const modal = useModal()

  const needsConfirmation = computed(() =>
    isPriceImpactDanger(unref(options.directPriceImpact))
    || isPriceImpactDanger(unref(options.multipliedPriceImpact) ?? null),
  )

  const guardWithPriceImpact = async (onProceed: () => void | Promise<void>) => {
    if (!needsConfirmation.value) {
      await onProceed()
      return
    }
    modal.open(HighPriceImpactModal, {
      props: {
        directPriceImpact: unref(options.directPriceImpact) ?? 0,
        multipliedPriceImpact: unref(options.multipliedPriceImpact) ?? null,
        onConfirm: async () => {
          modal.close()
          await onProceed()
        },
      },
    })
  }

  return { needsConfirmation, guardWithPriceImpact }
}
