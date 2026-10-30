<script setup>
// 后台独立登录页（/admin/login）
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { adminLogin } from '../composables/useAdminAuth.js'

const router = useRouter()
const username = ref('')
const password = ref('')
const err = ref('')
const loading = ref(false)

async function onSubmit() {
  err.value = ''
  loading.value = true
  try {
    await adminLogin({ username: username.value, password: password.value })
    router.push('/admin')
  } catch (e) {
    err.value = e.message
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="admin-login">
    <form class="card" @submit.prevent="onSubmit">
      <h1>🍜 美食社区 · 后台管理</h1>
      <p class="tip">请使用管理员账号登录</p>
      <input v-model.trim="username" placeholder="管理员用户名" autocomplete="username" required />
      <input v-model.trim="password" type="password" placeholder="密码" autocomplete="current-password" required />
      <p v-if="err" class="err">{{ err }}</p>
      <button :disabled="loading">{{ loading ? '登录中…' : '登 录' }}</button>
      <span class="back" @click="router.push('/login')">返回前台</span>
    </form>
  </div>
</template>

<style scoped>
.admin-login{
  min-height: 100vh; display: flex; align-items: center; justify-content: center;
  background: linear-gradient(140deg, #fff7ef, #ffe9d6);
}
.card{
  width: 340px; padding: 32px 28px; background: #fff; border-radius: 18px;
  box-shadow: 0 12px 40px rgba(255,90,60,.14); display: flex; flex-direction: column; gap: 12px;
}
h1{ font-size: 20px; margin: 0; color: #ff5a3c; text-align: center; }
.tip{ margin: 0 0 6px; font-size: 13px; color: #999; text-align: center; }
input{
  padding: 11px 14px; border: 1.5px solid #eee0d2; border-radius: 12px; font-size: 14px; outline: none;
}
input:focus{ border-color: #ff5a3c; }
.err{ margin: 0; color: #e5484d; font-size: 13px; }
button{
  padding: 12px; border: none; border-radius: 12px; cursor: pointer;
  background: linear-gradient(120deg, #ff7a45, #ff5a3c); color: #fff; font-size: 15px; font-weight: 700;
}
button:disabled{ opacity: .6; cursor: default; }
.back{ text-align: center; font-size: 13px; color: #999; cursor: pointer; }
.back:hover{ color: #ff5a3c; }
</style>
