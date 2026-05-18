<script setup lang="ts">
defineProps<{
  active: 'home' | 'diet' | 'training' | 'ai' | 'profile'
}>()

const tabs = [
  { key: 'home', icon: '⌂', text: '首页', url: '/pages/home/index' },
  { key: 'diet', icon: '🍲', text: '饮食', url: '/pages/diet/index' },
  { key: 'training', icon: '🏋', text: '训练', url: '/pages/training/index' },
  { key: 'ai', icon: '🤖', text: 'AI私教', url: '/pages/ai-chat/index' },
  { key: 'profile', icon: '♙', text: '我的', url: '/pages/profile/index' }
] as const

function go(url: string) {
  uni.reLaunch({ url })
}
</script>

<template>
  <view class="tabs">
    <button
      v-for="tab in tabs"
      :key="tab.key"
      class="tab-item"
      :class="{ active: active === tab.key }"
      type="button"
      @click="go(tab.url)"
    >
      <text class="icon">{{ tab.icon }}</text>
      <text>{{ tab.text }}</text>
    </button>
  </view>
</template>
