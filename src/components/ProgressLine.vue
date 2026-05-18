<script setup lang="ts">
defineProps<{ value: number }>()
</script>

<template>
  <view class="progress-line">
    <view class="progress-value" :style="{ width: `${value}%` }" />
  </view>
</template>

<style scoped>
.progress-line {
  height: 16rpx;
  overflow: hidden;
  border-radius: 99rpx;
  background: #edf0f2;
}

.progress-value {
  height: 100%;
  border-radius: 99rpx;
  background: linear-gradient(90deg, #12a85d, #0a8d45);
}
</style>
