<script setup lang="ts">
const props = defineProps<{
  title: string
  back?: boolean
  right?: string
}>()

function onBack() {
  if (props.back) {
    uni.navigateBack()
  }
}
</script>

<template>
  <view class="top-bar">
    <button class="left" type="button" @click="onBack">{{ back ? '‹' : '' }}</button>
    <text class="title">{{ title }}</text>
    <text class="right">{{ right || '' }}</text>
  </view>
</template>
