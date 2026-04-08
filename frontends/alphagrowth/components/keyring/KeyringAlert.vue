<script setup lang="ts">
const { isExpired = false } = defineProps<{
  isExpired?: boolean
}>()
</script>

<template>
  <div class="flex items-start gap-12 p-12 rounded-12 bg-accent-100/50 border border-accent-200">
    <div class="flex items-center justify-center w-32 h-32 rounded-8 bg-accent-100 shrink-0">
      <SvgIcon
        name="shield"
        class="!w-16 !h-16 text-accent-600"
      />
    </div>
    <div class="flex flex-col gap-4">
      <p class="text-p2 font-medium text-content-primary">
        {{ isExpired ? 'Verification Expired' : 'Identity Verification Required' }}
      </p>
      <p class="text-p3 text-content-secondary">
        {{ isExpired
          ? 'Your Keyring verification has expired. Please re-verify to continue using this vault.'
          : 'This vault requires identity verification via Keyring Network before you can interact with it.'
        }}
      </p>
    </div>
  </div>
</template>
