// 点赞（对接后端 MySQL food_db.post_like 表，需要登录）。
// 模块级 ref 让首页列表与详情页共享同一份状态；点赞数以后端 post.like_count 为准。
import { ref } from 'vue'
import { getToken } from './useAuth.js'
import { useToast } from './useToast.js'

const likedIds = ref(new Set())
const counts = ref(new Map())

export function useLikes() {
  function isLiked(id) {
    return likedIds.value.has(Number(id))
  }

  function countOf(id, fallback = 0) {
    const key = Number(id)
    return counts.value.has(key) ? counts.value.get(key) : (Number(fallback) || 0)
  }

  // 用 /api/posts 返回的 liked / likeCount 初始化（游客均为 false / 真实计数）
  function seed(posts) {
    if (!Array.isArray(posts)) return
    const nextLiked = new Set(likedIds.value)
    const nextCounts = new Map(counts.value)
    for (const p of posts) {
      if (!p || p.id == null) continue
      const key = Number(p.id)
      if (p.liked) nextLiked.add(key)
      else nextLiked.delete(key)
      nextCounts.set(key, Number(p.likeCount) || 0)
    }
    likedIds.value = nextLiked
    counts.value = nextCounts
  }

  // 切换点赞：调用后端接口落库（POST /api/posts/{id}/like）
  async function toggle(id, fallback = 0) {
    id = Number(id)
    if (!getToken()) { useToast().toast('请先登录后再点赞', 'error'); return null }
    try {
      const r = await fetch(`/api/posts/${id}/like`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}` }
      })
      const data = await r.json().catch(() => ({}))
      if (!r.ok) throw new Error(data.message || '点赞操作失败')

      const nextLiked = new Set(likedIds.value)
      if (data.liked) nextLiked.add(id)
      else nextLiked.delete(id)
      likedIds.value = nextLiked

      const nextCounts = new Map(counts.value)
      nextCounts.set(id, Number(data.likeCount) || 0)
      counts.value = nextCounts

      useToast().toast(data.liked ? '已点赞 ❤️' : '已取消点赞', data.liked ? 'success' : 'info')
      return data
    } catch (e) {
      useToast().toast(e.message || '点赞操作失败', 'error')
      return null
    }
  }

  return { likedIds, isLiked, countOf, seed, toggle }
}
