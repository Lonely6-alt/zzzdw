import { createRouter, createWebHistory } from 'vue-router'
import { getToken } from '../composables/useAuth.js'

import LoginView from '../views/LoginView.vue'
import HomeView from '../views/HomeView.vue'
import DiscoverView from '../views/DiscoverView.vue'
import PostDetail from '../views/PostDetail.vue'
import ProfileView from '../views/ProfileView.vue'
import MapView from '../views/MapView.vue'
import RankingView from '../views/RankingView.vue'

const routes = [
  { path: '/', name: 'home', component: HomeView, meta: { requiresAuth: true } },
  { path: '/discover', name: 'discover', component: DiscoverView, meta: { requiresAuth: true } },
  { path: '/login', name: 'login', component: LoginView },
  { path: '/profile', name: 'profile', component: ProfileView, meta: { requiresAuth: true } },
  { path: '/post/:id', name: 'post', component: PostDetail, meta: { requiresAuth: true } },
  { path: '/map', name: 'map', component: MapView, meta: { requiresAuth: true } },
  { path: '/ranking', name: 'ranking', component: RankingView, meta: { requiresAuth: true } }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 全局前置守卫：需要登录的路由若无 token 则跳登录页
router.beforeEach((to) => {
  if (to.meta.requiresAuth && !getToken()) return '/login'
})

export default router
