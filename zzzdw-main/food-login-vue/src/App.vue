<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { authUser, ensureSession, logout } from './composables/useAuth.js'
import { isAdmin } from './composables/useAdminAuth.js'
import { useToast } from './composables/useToast.js'
import ToastHost from './components/ToastHost.vue'
import OrderModal from './components/OrderModal.vue'

const router = useRouter()
const route = useRoute()
const { toast } = useToast()

// 后台相关路径不显示前台导航栏（避免重复导航）
const showNav = computed(() => !!authUser.value && !route.path.startsWith('/admin'))

// 滚动吸顶：下滑超过阈值后导航由半透明转为实色
const scrolled = ref(false)
function onScroll() { scrolled.value = window.scrollY > 24 }
const avatarChar = computed(() => (authUser.value || '?').trim().charAt(0).toUpperCase())

// 当前激活的导航项（用 path 前缀匹配，支持 /post 等子页高亮）
function isActive(p) {
  if (p === '/') return route.path === '/'
  return route.path.startsWith(p)
}
function go(p) {
  if (route.path !== p) router.push(p)
  else window.scrollTo({ top: 0, behavior: 'smooth' })
}
function onLogout() {
  logout()
  router.push('/login')
}
// 后台管理：所有人可见；管理员点击直接进后台，普通用户跳后台登录页
function onAdmin() {
  if (isAdmin.value) router.push('/admin')
  else router.push('/admin/login')
}

onMounted(async () => {
  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()
  const ok = await ensureSession()
  if (!ok && route.meta?.requiresAuth) router.push('/login')
  startUnreadPoll()
})
onUnmounted(() => {
  window.removeEventListener('scroll', onScroll)
  clearInterval(unreadTimer)
})

// ---- 私信未读红点：轮询 /api/chat/unread（5 秒一次，仅登录后） ----
const unreadCount = ref(0)
let unreadTimer = null
async function pollUnread() {
  try {
    const r = await fetch('/api/chat/unread', {
      headers: { Authorization: `Bearer ${localStorage.getItem('food_token')}` }
    })
    if (r.ok) unreadCount.value = (await r.json()).unread || 0
  } catch { /* 静默 */ }
}
function startUnreadPoll() {
  if (unreadTimer) clearInterval(unreadTimer)
  pollUnread()
  unreadTimer = setInterval(pollUnread, 5000)
}
</script>

<template>
  <div class="shell">
    <header v-if="showNav" class="topnav" :class="{ scrolled }">
      <div class="nav-inner">
        <div class="brand" @click="go('/')">🍲 食光 · 美食社区</div>

        <nav class="links">
          <button :class="{ on: isActive('/') }" @click="go('/')">首页</button>
          <button :class="{ on: isActive('/discover') }" @click="go('/discover')">发现</button>
          <button :class="{ on: isActive('/map') }" @click="go('/map')">美食地图</button>
          <button :class="{ on: isActive('/ranking') }" @click="go('/ranking')">排行榜</button>
          <button :class="{ on: isActive('/chat') }" class="msg-btn" @click="go('/chat')">
            消息
            <span v-if="unreadCount > 0" class="unread-dot">{{ unreadCount > 99 ? '99+' : unreadCount }}</span>
          </button>
          <button :class="{ on: isActive('/profile') }" @click="go('/profile')">我的</button>
          <button class="admin" @click="onAdmin">🛠 后台管理</button>
        </nav>

        <div class="right">
          <span class="avatar">{{ avatarChar }}</span>
          <span class="user">{{ authUser }}</span>
          <button class="out" @click="onLogout">退出</button>
        </div>
      </div>
    </header>

    <router-view />
    <OrderModal />
    <ToastHost />
  </div>
</template>

<style scoped>
.shell{ min-height:100vh; }
.topnav{
  position:sticky; top:0; z-index:30;
  background:rgba(255,247,238,.55); backdrop-filter:blur(6px);
  border-bottom:1.5px solid transparent;
  box-shadow:none;
  transition:background .3s, box-shadow .3s, border-color .3s;
}
.topnav.scrolled{
  background:rgba(255,247,238,.96); backdrop-filter:blur(12px);
  border-bottom:1.5px solid #f0e6db;
  box-shadow:0 6px 18px rgba(255,90,60,.08);
}
.nav-inner{
  max-width:1100px; margin:0 auto; padding:11px 18px;
  display:flex; align-items:center; gap:14px;
}
.brand{ font-weight:800; font-size:17px; cursor:pointer; white-space:nowrap; flex-shrink:0; }
.links{ display:flex; align-items:center; gap:4px; flex:1; justify-content:center; flex-wrap:wrap; }
.links button{
  border:0; background:transparent; color:var(--muted); font-weight:600; font-size:14px;
  padding:8px 14px; border-radius:999px; cursor:pointer; transition:.2s; white-space:nowrap;
}
.links button:hover{ color:var(--orange); background:#fff0ea; }
.links button.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); color:#fff;
  box-shadow:0 6px 14px rgba(255,90,60,.28); }
.links button.admin{
  background:linear-gradient(120deg,#5b6cff,#8a4bff); color:#fff;
  box-shadow:0 6px 14px rgba(96,80,255,.28); margin-left:6px;
}
.links button.admin:hover{ filter:brightness(1.06); color:#fff; }
.msg-btn{ position:relative; }
.unread-dot{ position:absolute; top:1px; right:2px; min-width:16px; height:16px; padding:0 4px; border-radius:8px;
  background:#ff3b30; color:#fff; font-size:10px; font-weight:800; line-height:16px; text-align:center;
  box-shadow:0 2px 6px rgba(255,59,48,.4); animation:dotIn .3s ease; }
@keyframes dotIn{ from{ transform:scale(0); } to{ transform:scale(1); } }
.right{ display:flex; align-items:center; gap:10px; flex-shrink:0; }
.avatar{ width:30px; height:30px; border-radius:50%; display:flex; align-items:center; justify-content:center;
  font-size:13px; font-weight:800; color:#fff; background:linear-gradient(140deg,var(--orange),var(--tomato)); box-shadow:0 4px 10px rgba(255,90,60,.3); flex-shrink:0; }
.user{ font-size:13px; color:var(--ink); font-weight:700; white-space:nowrap; }
.out{
  border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:7px 14px; border-radius:11px; cursor:pointer; font-weight:600; font-size:13px; transition:.2s;
}
.out:hover{ color:var(--err); border-color:var(--err); }

@media (max-width:680px){
  .nav-inner{ flex-wrap:wrap; gap:8px; padding:10px 12px; }
  .brand{ width:100%; }
  .links{ order:2; justify-content:flex-start; flex-wrap:wrap; }
  .right{ order:1; margin-left:auto; }
}
</style>
