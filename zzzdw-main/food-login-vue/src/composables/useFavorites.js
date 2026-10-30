// 收藏（对接后端 MySQL food_db.favorite 表，需要登录）。
// 模块级 ref 让各页面共享同一份状态；登录后自动拉取我的收藏。
import { ref } from 'vue'
import { getToken } from './useAuth.js'
import { useToast } from './useToast.js'

const ids = ref(new Set())

async function load() {
  if (!getToken()) return
  try {
    const r = await fetch('/api/favorites', { headers: { Authorization: `Bearer ${getToken()}` } })
    if (r.ok) {
      const list = await r.json()
      ids.value = new Set(list.map(p => Number(p.id)))
    }
  } catch { /* 网络异常时保持现状 */ }
}
load()

export function useFavorites() {
  function isFav(id) {
    return ids.value.has(Number(id))
  }
  // 切换收藏：调用后端接口落库（POST /api/posts/{id}/favorite）
  async function toggle(id) {
    id = Number(id)
    if (!getToken()) { useToast().toast('请先登录后再收藏', 'error'); return null }
    try {
      const r = await fetch(`/api/posts/${id}/favorite`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}` }
      })
      const data = await r.json().catch(() => ({}))
      if (!r.ok) throw new Error(data.message || '收藏操作失败')
      if (data.favorited) ids.value.add(id)
      else ids.value.delete(id)
      ids.value = new Set(ids.value) // 触发响应式更新
      return data
    } catch (e) {
      useToast().toast(e.message || '收藏操作失败', 'error')
      return null
    }
  }
  return { ids, isFav, toggle, load }
}
