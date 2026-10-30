// 全局轻提示；ToastHost.vue 负责渲染
import { ref } from 'vue'

const toasts = ref([])
let seq = 0

function toast(message, type = 'info', duration = 2600) {
  const id = ++seq
  toasts.value.push({ id, message, type })
  setTimeout(() => {
    toasts.value = toasts.value.filter(t => t.id !== id)
  }, duration)
}

export function useToast() {
  return { toast, toasts }
}
