<script setup lang="ts">
defineEmits(['close'])
const { modalTitle, text } = defineProps<{
  modalTitle: string
  text: string
}>()
</script>

<template>
  <BaseModalWrapper
    :title="modalTitle"
    @close="$emit('close')"
  >
    <div class="text-p2 text-content-primary">
      {{ text }}
    </div>
  </BaseModalWrapper>
</template>
