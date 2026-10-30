<script setup>
// 全局轻提示组件，App.vue 中挂载一次即可
import { useToast } from '../composables/useToast.js'
const { toasts } = useToast()
</script>

<template>
  <transition-group name="toast" tag="div" class="toast-host">
    <div v-for="t in toasts" :key="t.id" class="toast-item" :class="t.type">
      {{ t.message }}
    </div>
  </transition-group>
</template>

<style scoped>
.toast-host{
  position: fixed; top: 18px; left: 50%; transform: translateX(-50%);
  display: flex; flex-direction: column; gap: 10px; z-index: 9999;
  pointer-events: none;
}
.toast-item{
  padding: 10px 20px; border-radius: 12px; font-size: 14px; font-weight: 600;
  color: #fff; box-shadow: 0 8px 24px rgba(0,0,0,.18);
  background: #333;
}
.toast-item.success{ background: #2e9e5b; }
.toast-item.error{ background: #e5484d; }
.toast-item.info{ background: #3b6fe0; }
.toast-enter-active, .toast-leave-active{ transition: all .25s ease; }
.toast-enter-from, .toast-leave-to{ opacity: 0; transform: translateY(-10px); }
</style>
