// 评价（纯前端，localStorage 持久化）。结构：{ [postId]: [{ id, author, rating, comment, at }] }
import { ref } from 'vue'

const KEY = 'food_reviews'
let store = {}
try { store = JSON.parse(localStorage.getItem(KEY) || '{}') } catch { store = {} }
const reviews = ref(store)

function persist() {
  localStorage.setItem(KEY, JSON.stringify(reviews.value))
}

export function useReviews() {
  // 某帖子的全部评价
  function getReviews(postId) {
    return reviews.value[postId] || []
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
  function add(postId, { author, rating, comment }) {
    const entry = { id: Date.now(), author, rating, comment, at: Date.now() }
    reviews.value = {
      ...reviews.value,
      [postId]: [entry, ...(reviews.value[postId] || [])]
    }
    persist()
    return entry
  }
  // 全部评价（用于首页热门点评 / 排行榜），含 postId 便于跳转
  function allReviews() {
    const out = []
    for (const pid in reviews.value) {
      for (const r of reviews.value[pid]) out.push({ postId: Number(pid), ...r })
    }
    return out
  }
  return { reviews, getReviews, avgRating, count, add, allReviews }
}
