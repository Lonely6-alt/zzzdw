<script setup>
// 美食笔记审核：按状态筛选 / 通过 / 驳回 / 删除
import { ref, onMounted } from 'vue'
import { adminFetch } from '../../composables/useAdminAuth.js'
import { useToast } from '../../composables/useToast.js'

const { toast } = useToast()
const posts = ref([])
const filter = ref('pending')
const err = ref('')

async function load() {
  try {
    const q = filter.value ? `?status=${filter.value}` : ''
    posts.value = await adminFetch(`/api/admin/posts${q}`)
  } catch (e) { err.value = e.message }
}
onMounted(load)

async function setStatus(p, status) {
  try {
    await adminFetch(`/api/admin/posts/${p.id}`, { method: 'PATCH', body: JSON.stringify({ status }) })
    toast(status === 'approved' ? '已通过' : '已驳回', 'success')
    load()
  } catch (e) { toast(e.message, 'error') }
}
async function remove(p) {
  if (!confirm(`确定删除笔记「${p.title}」？`)) return
  try {
    await adminFetch(`/api/admin/posts/${p.id}`, { method: 'DELETE' })
    toast('已删除', 'success')
    load()
  } catch (e) { toast(e.message, 'error') }
}
function fmtDate(s) { return (s || '').slice(0, 10) }
</script>

<template>
  <div>
    <h2>美食笔记审核</h2>
    <div class="bar">
      <button v-for="f in [
        { v: 'pending', label: '待审核' },
        { v: 'approved', label: '已通过' },
        { v: 'rejected', label: '已驳回' },
        { v: '', label: '全部' }
      ]" :key="f.v" :class="{ active: filter === f.v }" @click="filter = f.v; load()">{{ f.label }}</button>
    </div>
    <p v-if="err" class="err">{{ err }}</p>
    <p v-else-if="!posts.length" class="empty">暂无笔记</p>
    <div v-else class="list">
      <div v-for="p in posts" :key="p.id" class="item">
        <div class="head">
          <span class="emoji">{{ p.emoji }}</span>
          <b>{{ p.title }}</b>
          <span class="meta">{{ p.category }} · {{ p.author }} · {{ fmtDate(p.createdAt) }}</span>
          <span :class="['tag', p.status]">{{ { pending: '待审核', approved: '已通过', rejected: '已驳回' }[p.status] }}</span>
        </div>
        <p class="content">{{ p.content }}</p>
        <div class="ops">
          <button v-if="p.status !== 'approved'" class="ok" @click="setStatus(p, 'approved')">通过</button>
          <button v-if="p.status !== 'rejected'" @click="setStatus(p, 'rejected')">驳回</button>
          <button class="danger" @click="remove(p)">删除</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
h2{ margin: 0 0 16px; color: #3a2f2a; }
.bar{ display: flex; gap: 8px; margin-bottom: 16px; }
.bar button{
  padding: 8px 16px; border: 1.5px solid #eee0d2; border-radius: 10px; background: #fff;
  cursor: pointer; font-size: 13px;
}
.bar button.active{ background: linear-gradient(120deg, #ff7a45, #ff5a3c); color: #fff; border-color: transparent; }
.list{ display: flex; flex-direction: column; gap: 12px; }
.item{ background: #fff; border-radius: 14px; padding: 14px 18px; box-shadow: 0 4px 16px rgba(60,40,20,.06); }
.head{ display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.emoji{ font-size: 20px; }
.meta{ font-size: 12px; color: #999; }
.tag{ margin-left: auto; font-size: 12px; padding: 3px 10px; border-radius: 8px; }
.tag.pending{ background: #fff3e0; color: #d9822b; }
.tag.approved{ background: #e6f6ec; color: #2e9e5b; }
.tag.rejected{ background: #fdecec; color: #e5484d; }
.content{ margin: 8px 0 10px; font-size: 13px; color: #666; line-height: 1.6; }
.ops button{
  margin-right: 8px; padding: 5px 14px; border: 1.5px solid #eee0d2; border-radius: 8px;
  background: #fff; cursor: pointer; font-size: 12px;
}
.ops .ok{ background: #2e9e5b; color: #fff; border-color: transparent; }
.ops .danger{ color: #e5484d; }
.ops button:hover:not(.ok){ border-color: #ff5a3c; color: #ff5a3c; }
.err, .empty{ color: #999; }
</style>
