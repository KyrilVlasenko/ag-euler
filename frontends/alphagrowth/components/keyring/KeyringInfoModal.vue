<script setup lang="ts">
defineEmits(['close'])
</script>

<template>
  <BaseModalWrapper
    title="Private Vault"
    @close="$emit('close')"
  >
    <div class="flex flex-col gap-16 pt-8">
      <div class="flex items-center justify-center">
        <div class="flex items-center justify-center w-48 h-48 rounded-12 bg-accent-100">
          <SvgIcon
            name="shield"
            class="!w-24 !h-24 text-accent-600"
          />
        </div>
      </div>

      <div class="flex flex-col gap-8">
        <p class="text-p2 text-content-primary text-center font-medium">
          Identity Verification Required
        </p>
        <p class="text-p3 text-content-secondary text-center">
          This vault requires identity verification through Keyring Network before you can interact with it.
        </p>
      </div>

      <div class="flex flex-col gap-8 p-12 rounded-12 bg-surface-secondary">
        <div class="flex items-start gap-8">
          <SvgIcon
            name="check-circle"
            class="!w-16 !h-16 text-accent-600 mt-2 shrink-0"
          />
          <p class="text-p3 text-content-secondary">
            Install the Keyring browser extension to complete verification
          </p>
        </div>
        <div class="flex items-start gap-8">
          <SvgIcon
            name="check-circle"
            class="!w-16 !h-16 text-accent-600 mt-2 shrink-0"
          />
          <p class="text-p3 text-content-secondary">
            Credentials expire after a limited time and may need periodic renewal
          </p>
        </div>
        <div class="flex items-start gap-8">
          <SvgIcon
            name="check-circle"
            class="!w-16 !h-16 text-accent-600 mt-2 shrink-0"
          />
          <p class="text-p3 text-content-secondary">
            A small on-chain fee is paid during credential registration
          </p>
        </div>
      </div>

      <UiButton
        variant="primary"
        size="large"
        @click="$emit('close')"
      >
        Got it
      </UiButton>
    </div>
  </BaseModalWrapper>
</template>
