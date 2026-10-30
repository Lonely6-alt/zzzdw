<script setup>
// 后台管理布局：左侧菜单 + 右侧内容
import { useRouter } from 'vue-router'
import { clearAdminToken } from '../../composables/useAdminAuth.js'

const router = useRouter()
const menus = [
  { path: '/admin', label: '数据仪表盘', icon: '📊', exact: true },
  { path: '/admin/users', label: '用户管理', icon: '👥' },
  { path: '/admin/reviews', label: '美食笔记审核', icon: '📝' },
  { path: '/admin/categories', label: '美食分类管理', icon: '🍜' },
  { path: '/admin/tags', label: '热门标签管理', icon: '🔥' },
  { path: '/admin/comments', label: '评论管理', icon: '💬' }
]

function isActive(m) {
  return m.exact ? router.currentRoute.value.path === m.path : router.currentRoute.value.path.startsWith(m.path)
}
function onLogout() {
  clearAdminToken()
  router.push('/admin/login')
}
</script>

<template>
  <div class="admin-layout">
    <aside class="side">
      <div class="logo">🍜 美食后台</div>
      <nav>
        <button v-for="m in menus" :key="m.path" :class="{ active: isActive(m) }" @click="router.push(m.path)">
          <span>{{ m.icon }}</span>{{ m.label }}
        </button>
      </nav>
      <button class="out" @click="onLogout">退出后台</button>
    </aside>
    <main class="content"><router-view /></main>
  </div>
</template>

<style scoped>
.admin-layout{ min-height: 100vh; display: flex; background: #f7f4ef; }
.side{
  width: 220px; background: #2b2320; color: #fff; display: flex; flex-direction: column;
  padding: 20px 14px; gap: 8px; position: sticky; top: 0; height: 100vh; box-sizing: border-box;
}
.logo{ font-size: 17px; font-weight: 800; padding: 4px 8px 16px; }
nav{ display: flex; flex-direction: column; gap: 6px; flex: 1; }
nav button{
  display: flex; align-items: center; gap: 10px; padding: 11px 14px; border: none; border-radius: 12px;
  background: transparent; color: #d8cfc9; font-size: 14px; cursor: pointer; text-align: left;
}
nav button:hover{ background: rgba(255,255,255,.08); color: #fff; }
nav button.active{ background: linear-gradient(120deg, #ff7a45, #ff5a3c); color: #fff; font-weight: 700; }
.out{
  padding: 10px; border: 1.5px solid #4a3f39; border-radius: 12px; background: transparent;
  color: #d8cfc9; cursor: pointer; font-size: 13px;
}
.out:hover{ border-color: #ff5a3c; color: #ff5a3c; }
.content{ flex: 1; padding: 26px 30px; box-sizing: border-box; }
</style>
