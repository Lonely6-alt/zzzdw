<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { authUser, ensureSession, logout } from './composables/useAuth.js'

const router = useRouter()

function onLogout() {
  logout()
  router.push('/login')
}

onMounted(async () => {
  const ok = await ensureSession()
  if (!ok && router.currentRoute.value.meta?.requiresAuth) router.push('/login')
})
</script>

<template>
  <div class="shell">
    <header v-if="authUser" class="gbar">
      <div class="brand" @click="router.push('/')">🍲 食光 · 美食社区</div>
      <button class="out" @click="onLogout">退出登录</button>
    </header>
    <router-view />
  </div>
</template>

<style scoped>
.shell{ min-height:100vh; }
.gbar{
  position:sticky; top:0; z-index:10;
  display:flex; align-items:center; justify-content:space-between;
  padding:14px 24px; background:rgba(255,247,238,.85); backdrop-filter:blur(8px);
  border-bottom:1px solid #f0e6db;
}
.gbar .brand{ font-weight:800; font-size:17px; cursor:pointer; }
.gbar .out{
  border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:7px 14px; border-radius:11px; cursor:pointer; font-weight:600;
}
.gbar .out:hover{ color:var(--err); border-color:var(--err); }
</style>
