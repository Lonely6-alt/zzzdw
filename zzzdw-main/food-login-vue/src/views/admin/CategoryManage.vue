<script setup>
// 美食分类管理：增删改图标
import { ref, onMounted } from 'vue'
import { adminFetch } from '../../composables/useAdminAuth.js'
import { useToast } from '../../composables/useToast.js'

const { toast } = useToast()
const cats = ref([])
const name = ref('')
const icon = ref('')
const err = ref('')

async function load() {
  try { cats.value = await adminFetch('/api/admin/categories') }
  catch (e) { err.value = e.message }
}
onMounted(load)

async function add() {
  try {
    await adminFetch('/api/admin/categories', {
      method: 'POST', body: JSON.stringify({ name: name.value, icon: icon.value || '🍽️' })
    })
    toast('分类已添加', 'success')
    name.value = ''; icon.value = ''
    load()
  } catch (e) { toast(e.message, 'error') }
}
async function changeIcon(c) {
  const v = prompt(`修改「${c.name}」的图标 emoji：`, c.icon)
  if (v == null || !v.trim()) return
  try {
    await adminFetch(`/api/admin/categories/${encodeURIComponent(c.name)}`, {
      method: 'PUT', body: JSON.stringify({ icon: v.trim() })
    })
    load()
  } catch (e) { toast(e.message, 'error') }
}
async function remove(c) {
  if (!confirm(`确定删除分类「${c.name}」？其下笔记将归入「未分类」。`)) return
  try {
    await adminFetch(`/api/admin/categories/${encodeURIComponent(c.name)}`, { method: 'DELETE' })
    toast('已删除', 'success')
    load()
  } catch (e) { toast(e.message, 'error') }
}
</script>

<template>
  <div>
    <h2>美食分类管理</h2>
    <form class="bar" @submit.prevent="add">
      <input v-model.trim="name" placeholder="新分类名称" required />
      <input v-model.trim="icon" placeholder="图标 emoji(可选)" style="width:160px" />
      <button>添加分类</button>
    </form>
    <p v-if="err" class="err">{{ err }}</p>
    <div v-else class="grid">
      <div v-for="c in cats" :key="c.name" class="card">
        <span class="ic">{{ c.icon }}</span>
        <b>{{ c.name }}</b>
        <div class="ops">
          <button @click="changeIcon(c)">改图标</button>
          <button class="danger" @click="remove(c)">删除</button>
        </div>
      </div>
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
.grid{ display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
.card{
  background: #fff; border-radius: 14px; padding: 16px; display: flex; flex-direction: column;
  align-items: center; gap: 6px; box-shadow: 0 4px 16px rgba(60,40,20,.06);
}
.ic{ font-size: 28px; }
.ops{ display: flex; gap: 6px; }
.ops button{
  padding: 4px 10px; border: 1.5px solid #eee0d2; border-radius: 8px; background: #fff;
  cursor: pointer; font-size: 12px;
}
.ops button:hover{ border-color: #ff5a3c; color: #ff5a3c; }
.ops .danger{ color: #e5484d; }
.err{ color: #e5484d; }
</style>
