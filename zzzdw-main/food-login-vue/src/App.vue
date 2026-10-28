<script setup>
import { computed } from 'vue'
import { onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { authUser, ensureSession, logout } from './composables/useAuth.js'
import { isAdmin } from './composables/useAdminAuth.js'
import { useToast } from './composables/useToast.js'
import ToastHost from './components/ToastHost.vue'
import OrderModal from './components/OrderModal.vue'

const router = useRouter()
const route = useRoute()
const { toast } = useToast()

// 后台相关路径不显示前台导航栏
const showNav = computed(() => authUser.value && !route.path.startsWith('/admin'))

function onLogout() {
  logout()
  router.push('/login')
}
function goProfile() {
  router.push('/profile')
}
// 后台管理入口：管理员直接进入；普通用户提示无权限
function onAdmin() {
  if (isAdmin.value) router.push('/admin')
  else toast('您没有管理员权限', 'error')
}

onMounted(async () => {
  const ok = await ensureSession()
  if (!ok && route.meta?.requiresAuth) router.push('/login')
})
</script>

<template>
  <div class="shell">
    <header v-if="showNav" class="gbar">
      <div class="brand" @click="router.push('/')">🍲 食光 · 美食社区</div>
      <div class="gbar-right">
        <button class="nav" @click="router.push('/')">首页</button>
        <button class="nav" @click="router.push('/discover')">发现</button>
        <button class="nav" @click="router.push('/map')">美食地图</button>
        <button class="nav" @click="router.push('/ranking')">排行榜</button>
        <button class="nav admin-entry" @click="onAdmin">后台管理</button>
        <button class="mine" @click="goProfile">我的</button>
        <button class="out" @click="onLogout">退出登录</button>
      </div>
    </header>
    <router-view />
    <OrderModal />
    <ToastHost />
  </div>
</template>

<style scoped>
.shell{ min-height:100vh; }
.gbar{
  position:sticky; top:0; z-index:10;
  display:flex; align-items:center; justify-content:center; gap:22px;
  padding:14px 24px; background:rgba(255,247,238,.85); backdrop-filter:blur(8px);
  border-bottom:1px solid #f0e6db;
}
.gbar .brand{ font-weight:800; font-size:17px; cursor:pointer; }
.gbar .out{
  border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:7px 14px; border-radius:11px; cursor:pointer; font-weight:600;
}
.gbar .out:hover{ color:var(--err); border-color:var(--err); }
.gbar-right{ display:flex; align-items:center; gap:10px; }
.gbar .nav{
  border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:7px 14px; border-radius:11px; cursor:pointer; font-weight:600; transition:.2s;
}
.gbar .nav:hover{ border-color:var(--orange); color:var(--tomato); }
.gbar .nav.admin-entry{
  border:1.5px solid #ffd9b0; color:var(--tomato);
  background:linear-gradient(120deg,#fff3e6,#ffe6cf);
}
.gbar .nav.admin-entry:hover{ border-color:var(--tomato); box-shadow:0 6px 16px rgba(255,90,60,.18); }
.gbar .mine{
  border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:7px 14px; border-radius:11px; cursor:pointer; font-weight:600; transition:.2s;
}
.gbar .mine:hover{ border-color:var(--orange); color:var(--tomato); }
</style>
