import { createRouter, createWebHistory } from 'vue-router'
import { getToken } from '../composables/useAuth.js'

import LoginView from '../views/LoginView.vue'
import HomeView from '../views/HomeView.vue'
import PostDetail from '../views/PostDetail.vue'

const routes = [
  { path: '/', name: 'home', component: HomeView, meta: { requiresAuth: true } },
  { path: '/login', name: 'login', component: LoginView },
  { path: '/post/:id', name: 'post', component: PostDetail, meta: { requiresAuth: true } }
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
