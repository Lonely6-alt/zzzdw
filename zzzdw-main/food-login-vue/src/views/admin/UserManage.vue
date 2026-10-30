<script setup>
// 用户管理：列表 / 新建 / 改角色状态 / 删除
import { ref, onMounted } from 'vue'
import { adminFetch } from '../../composables/useAdminAuth.js'
import { useToast } from '../../composables/useToast.js'

const { toast } = useToast()
const users = ref([])
const form = ref({ username: '', password: '', role: 'user' })
const err = ref('')

async function load() {
  try { users.value = await adminFetch('/api/admin/users') }
  catch (e) { err.value = e.message }
}
onMounted(load)

async function addUser() {
  try {
    await adminFetch('/api/admin/users', { method: 'POST', body: JSON.stringify(form.value) })
    toast('用户已创建', 'success')
    form.value = { username: '', password: '', role: 'user' }
    load()
  } catch (e) { toast(e.message, 'error') }
}
async function patch(u, body) {
  try {
    await adminFetch(`/api/admin/users/${u.username}`, { method: 'PATCH', body: JSON.stringify(body) })
    load()
  } catch (e) { toast(e.message, 'error') }
}
async function remove(u) {
  if (!confirm(`确定删除用户「${u.username}」？`)) return
  try {
    await adminFetch(`/api/admin/users/${u.username}`, { method: 'DELETE' })
    toast('已删除', 'success')
    load()
  } catch (e) { toast(e.message, 'error') }
}
function fmtDate(s) { return (s || '').slice(0, 10) }
</script>

<template>
  <div>
    <h2>用户管理</h2>
    <form class="bar" @submit.prevent="addUser">
      <input v-model.trim="form.username" placeholder="用户名(≥3字符)" required />
      <input v-model.trim="form.password" placeholder="密码(≥6位)" required />
      <select v-model="form.role">
        <option value="user">普通用户</option>
        <option value="admin">管理员</option>
      </select>
      <button>新增用户</button>
    </form>
    <p v-if="err" class="err">{{ err }}</p>
    <table v-else>
      <thead><tr><th>用户名</th><th>角色</th><th>状态</th><th>注册时间</th><th>操作</th></tr></thead>
      <tbody>
        <tr v-for="u in users" :key="u.username">
          <td>{{ u.username }}</td>
          <td>{{ u.role === 'admin' ? '管理员' : '普通用户' }}</td>
          <td><span :class="['st', u.status]">{{ u.status === 'active' ? '正常' : '已禁用' }}</span></td>
          <td>{{ fmtDate(u.createdAt) }}</td>
          <td class="ops">
            <button @click="patch(u, { status: u.status === 'active' ? 'disabled' : 'active' })">
              {{ u.status === 'active' ? '禁用' : '启用' }}
            </button>
            <button v-if="u.role !== 'admin'" @click="patch(u, { role: 'admin' })">设为管理员</button>
            <button v-else class="danger" disabled>管理员账号</button>
            <button v-if="u.role !== 'admin'" class="danger" @click="remove(u)">删除</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
h2{ margin: 0 0 16px; color: #3a2f2a; }
.bar{ display: flex; gap: 8px; margin-bottom: 16px; flex-wrap: wrap; }
input, select{
  padding: 9px 12px; border: 1.5px solid #eee0d2; border-radius: 10px; font-size: 13px; outline: none;
}
input:focus{ border-color: #ff5a3c; }
.bar button{
  padding: 9px 18px; border: none; border-radius: 10px; cursor: pointer;
  background: linear-gradient(120deg, #ff7a45, #ff5a3c); color: #fff; font-weight: 700;
}
table{ width: 100%; border-collapse: collapse; background: #fff; border-radius: 14px; overflow: hidden; }
th, td{ padding: 11px 14px; text-align: left; font-size: 13px; border-bottom: 1px solid #f3ece4; }
th{ background: #faf5ee; color: #8a7a6d; }
.st.active{ color: #2e9e5b; }
.st.disabled{ color: #e5484d; }
.ops button{
  margin-right: 6px; padding: 5px 10px; border: 1.5px solid #eee0d2; border-radius: 8px;
  background: #fff; cursor: pointer; font-size: 12px;
}
.ops button:hover:not(:disabled){ border-color: #ff5a3c; color: #ff5a3c; }
.ops button.danger{ color: #e5484d; }
.ops button:disabled{ opacity: .5; cursor: default; }
.err{ color: #e5484d; }
</style>
