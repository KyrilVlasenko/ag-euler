<script setup lang="ts">
defineProps<{
  title: string
  description: string
}>()
defineEmits(['close'])
</script>

<template>
  <BaseModalWrapper
    title="Vault Type"
    @close="$emit('close')"
  >
    <div class="flex flex-col gap-16 pt-8">
      <p class="text-h4 text-content-primary">
        {{ title }}
      </p>
      <p class="text-p3 text-content-secondary leading-relaxed">
        {{ description }}
      </p>
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
