// 评价（后端持久化，comments.json）。结构：{ id, postId, author, rating, comment, at }
// 对外暴露与旧版一致的同步 getter；首次使用时拉取全部评论到内存，之后响应式更新。
import { ref } from 'vue'
import { getToken } from './useAuth.js'

const API = '/api'
const comments = ref([])   // 全部评论（含 postId）
let loaded = false
let loading = false

async function ensureLoaded() {
  if (loaded || loading) return
  loading = true
  try {
    const r = await fetch(`${API}/comments`)
    if (r.ok) comments.value = await r.json()
  } catch { /* 网络异常时保持空列表 */ }
  finally { loaded = true; loading = false }
}

export function useReviews() {
  // 某帖子的全部评价
  function getReviews(postId) {
    ensureLoaded()
    return comments.value.filter(c => c.postId === Number(postId))
  }
  // 某帖子平均评分（0 表示暂无评价）
  function avgRating(postId) {
    const list = getReviews(postId)
    if (!list.length) return 0
    return list.reduce((s, r) => s + r.rating, 0) / list.length
  }
  function count(postId) {
    return getReviews(postId).length
  }
  // 发布评价（需登录）
  async function add(postId, { author, rating, comment }) {
    const r = await fetch(`${API}/posts/${postId}/comments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${getToken()}` },
      body: JSON.stringify({ author, rating, comment })
    })
    const data = await r.json().catch(() => ({}))
    if (!r.ok) throw new Error(data.message || '发布失败')
    comments.value = [data, ...comments.value]
    return data
  }
  // 全部评价（用于首页热门点评 / 排行榜），含 postId 便于跳转
  function allReviews() {
    ensureLoaded()
    return [...comments.value].sort((a, b) => b.id - a.id)
  }
  return { comments, getReviews, avgRating, count, add, allReviews, ensureLoaded }
}
