<script setup>
// 热门标签管理：增删
import { ref, onMounted } from 'vue'
import { adminFetch } from '../../composables/useAdminAuth.js'
import { useToast } from '../../composables/useToast.js'

const { toast } = useToast()
const tags = ref([])
const name = ref('')
const err = ref('')

async function load() {
  try { tags.value = await adminFetch('/api/admin/tags') }
  catch (e) { err.value = e.message }
}
onMounted(load)

async function add() {
  try {
    await adminFetch('/api/admin/tags', { method: 'POST', body: JSON.stringify({ name: name.value }) })
    toast('标签已添加', 'success')
    name.value = ''
    load()
  } catch (e) { toast(e.message, 'error') }
}
async function remove(t) {
  if (!confirm(`确定删除标签「${t.name}」？`)) return
  try {
    await adminFetch(`/api/admin/tags/${encodeURIComponent(t.name)}`, { method: 'DELETE' })
    toast('已删除', 'success')
    load()
  } catch (e) { toast(e.message, 'error') }
}
</script>

<template>
  <div>
    <h2>热门标签管理</h2>
    <form class="bar" @submit.prevent="add">
      <input v-model.trim="name" placeholder="新标签名称" required />
      <button>添加标签</button>
    </form>
    <p v-if="err" class="err">{{ err }}</p>
    <div v-else class="cloud">
      <span v-for="t in tags" :key="t.name" class="tag">
        # {{ t.name }}<i>热度 {{ t.heat }}</i>
        <button @click="remove(t)">✕</button>
      </span>
    </div>
  </div>
</template>

<style scoped>
h2{ margin: 0 0 16px; color: #3a2f2a; }
.bar{ display: flex; gap: 8px; margin-bottom: 16px; }
input{ padding: 9px 12px; border: 1.5px solid #eee0d2; border-radius: 10px; font-size: 13px; outline: none; }
input:focus{ border-color: #ff5a3c; }
.bar button{
  padding: 9px 18px; border: none; border-radius: 10px; cursor: pointer;
  background: linear-gradient(120deg, #ff7a45, #ff5a3c); color: #fff; font-weight: 700;
}
.cloud{ display: flex; flex-wrap: wrap; gap: 10px; }
.tag{
  display: inline-flex; align-items: center; gap: 8px; padding: 8px 14px; border-radius: 999px;
  background: #fff; font-size: 13px; color: #6b5443; box-shadow: 0 4px 14px rgba(60,40,20,.06);
}
.tag i{ font-style: normal; font-size: 12px; color: #bbb; }
.tag button{
  border: none; background: #f6efe7; border-radius: 50%; width: 20px; height: 20px;
  cursor: pointer; font-size: 11px; color: #e5484d; line-height: 1;
}
.tag button:hover{ background: #fdecec; }
.err{ color: #e5484d; }
</style>
