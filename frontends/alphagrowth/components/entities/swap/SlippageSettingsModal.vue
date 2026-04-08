<script setup lang="ts">
import SlippageSettings from '~/components/entities/swap/SlippageSettings.vue'

const emit = defineEmits(['close'])
const slippageRef = ref<InstanceType<typeof SlippageSettings> | null>(null)

const onSave = () => {
  if (slippageRef.value?.savePending() === false) return
  emit('close')
}
</script>

<template>
  <BaseModalWrapper
    @close="emit('close')"
  >
    <SlippageSettings
      ref="slippageRef"
      defer-save
    />
    <UiButton
      variant="primary"
      size="xlarge"
      @click="onSave"
    >
      Save
    </UiButton>
  </BaseModalWrapper>
</template>
