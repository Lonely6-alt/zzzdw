// 收藏（纯前端，使用 localStorage 持久化）。模块级 ref 让各页面共享同一份状态。
import { ref } from 'vue'

const KEY = 'food_favorites'
const ids = ref(new Set(JSON.parse(localStorage.getItem(KEY) || '[]')))

function persist() {
  localStorage.setItem(KEY, JSON.stringify([...ids.value]))
}

export function useFavorites() {
  function isFav(id) {
    return ids.value.has(Number(id))
  }
  function toggle(id) {
    id = Number(id)
    if (ids.value.has(id)) ids.value.delete(id)
    else ids.value.add(id)
    ids.value = new Set(ids.value) // 触发响应式更新
    persist()
  }
  return { ids, isFav, toggle }
}
