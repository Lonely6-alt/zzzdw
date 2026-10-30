<script setup>
// 数据仪表盘：展示后台统计
import { ref, onMounted } from 'vue'
import { adminFetch } from '../../composables/useAdminAuth.js'

const stats = ref(null)
const err = ref('')

onMounted(async () => {
  try { stats.value = await adminFetch('/api/admin/stats') }
  catch (e) { err.value = e.message }
})
const cards = [
  { key: 'users', label: '注册用户', icon: '👥' },
  { key: 'usersActive', label: '正常状态用户', icon: '✅' },
  { key: 'posts', label: '美食笔记', icon: '📝' },
  { key: 'postsPending', label: '待审核笔记', icon: '⏳' },
  { key: 'postsApproved', label: '已通过笔记', icon: '🍚' },
  { key: 'comments', label: '评论总数', icon: '💬' },
  { key: 'categories', label: '美食分类', icon: '🍜' },
  { key: 'tags', label: '热门标签', icon: '🔥' }
]
</script>

<template>
  <div>
    <h2>数据仪表盘</h2>
    <p v-if="err" class="err">{{ err }}</p>
    <div v-else-if="stats" class="grid">
      <div v-for="c in cards" :key="c.key" class="card">
        <span class="icon">{{ c.icon }}</span>
        <b>{{ stats[c.key] }}</b>
        <span class="label">{{ c.label }}</span>
      </div>
    </div>
    <p v-else class="loading">加载中…</p>
  </div>
</template>

<style scoped>
h2{ margin: 0 0 18px; color: #3a2f2a; }
.grid{ display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 14px; }
.card{
  background: #fff; border-radius: 16px; padding: 18px; display: flex; flex-direction: column; gap: 4px;
  box-shadow: 0 4px 16px rgba(60,40,20,.06);
}
.icon{ font-size: 22px; }
.card b{ font-size: 26px; color: #ff5a3c; }
.label{ font-size: 13px; color: #999; }
.err{ color: #e5484d; }
.loading{ color: #999; }
</style>
