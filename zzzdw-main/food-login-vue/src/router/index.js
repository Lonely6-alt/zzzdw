import { createRouter, createWebHistory } from 'vue-router'
import { getToken } from '../composables/useAuth.js'
import { getAdminToken } from '../composables/useAdminAuth.js'

import LoginView from '../views/LoginView.vue'
import HomeView from '../views/HomeView.vue'
import DiscoverView from '../views/DiscoverView.vue'
import PostDetail from '../views/PostDetail.vue'
import ProfileView from '../views/ProfileView.vue'
import MapView from '../views/MapView.vue'
import RankingView from '../views/RankingView.vue'
import AdminLoginView from '../views/AdminLoginView.vue'
import AdminDashboard from '../views/AdminDashboard.vue'

const routes = [
  { path: '/', name: 'home', component: HomeView, meta: { requiresAuth: true } },
  { path: '/discover', name: 'discover', component: DiscoverView, meta: { requiresAuth: true } },
  { path: '/login', name: 'login', component: LoginView },
  { path: '/profile', name: 'profile', component: ProfileView, meta: { requiresAuth: true } },
  { path: '/post/:id', name: 'post', component: PostDetail, meta: { requiresAuth: true } },
  { path: '/map', name: 'map', component: MapView, meta: { requiresAuth: true } },
  { path: '/ranking', name: 'ranking', component: RankingView, meta: { requiresAuth: true } },
  { path: '/admin/login', name: 'admin-login', component: AdminLoginView },
  { path: '/admin', name: 'admin', component: AdminDashboard, meta: { requiresAdmin: true } }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 全局前置守卫：需要登录/管理员权限的路由若无对应 token 则跳对应登录页
router.beforeEach((to) => {
  if (to.meta.requiresAuth && !getToken()) return '/login'
  if (to.meta.requiresAdmin && !getAdminToken()) return '/admin/login'
})

export default router
