<script setup lang="ts">
const { shouldShowHint, hiddenBorrowCount, hiddenDepositCount, dismissHint } = useShowAllHint()
</script>

<template>
  <Transition name="hint">
    <div
      v-if="shouldShowHint"
      class="flex items-center gap-8 bg-warning-100 rounded-12 p-12 mx-16"
    >
      <SvgIcon
        name="info-circle"
        class="!w-20 !h-20 text-warning-500 shrink-0"
      />
      <span class="text-warning-500 text-p4 flex-1">
        This application shows only a subset of vaults selected by the app provider.
        You have {{ hiddenBorrowCount }} position{{ hiddenBorrowCount !== 1 ? 's' : '' }}
        and {{ hiddenDepositCount }} deposit{{ hiddenDepositCount !== 1 ? 's' : '' }}
        in unverified vaults that are hidden by default.
        Interacting with unverified vaults may pose security risks.
        Use the "Show all" toggle to reveal them.
      </span>
      <button
        type="button"
        class="shrink-0 w-20 h-20 flex items-center justify-center self-start text-warning-500 hover:text-warning-500/70 transition-colors"
        @click="dismissHint"
      >
        &#x2715;
      </button>
    </div>
  </Transition>
</template>

<style scoped>
.hint-enter-active,
.hint-leave-active {
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.hint-enter-from,
.hint-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
