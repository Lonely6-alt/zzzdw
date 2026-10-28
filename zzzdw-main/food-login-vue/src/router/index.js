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
import AdminLayout from '../views/admin/AdminLayout.vue'
import AdminDashboard from '../views/admin/AdminDashboard.vue'
import UserManage from '../views/admin/UserManage.vue'
import NoteReview from '../views/admin/NoteReview.vue'
import CategoryManage from '../views/admin/CategoryManage.vue'
import TagManage from '../views/admin/TagManage.vue'
import CommentManage from '../views/admin/CommentManage.vue'

const routes = [
  { path: '/', name: 'home', component: HomeView, meta: { requiresAuth: true } },
  { path: '/discover', name: 'discover', component: DiscoverView, meta: { requiresAuth: true } },
  { path: '/login', name: 'login', component: LoginView },
  { path: '/profile', name: 'profile', component: ProfileView, meta: { requiresAuth: true } },
  { path: '/post/:id', name: 'post', component: PostDetail, meta: { requiresAuth: true } },
  { path: '/map', name: 'map', component: MapView, meta: { requiresAuth: true } },
  { path: '/ranking', name: 'ranking', component: RankingView, meta: { requiresAuth: true } },

  // 后台登录（独立页）
  { path: '/admin/login', name: 'admin-login', component: AdminLoginView },
  // 后台管理（需管理员权限）
  {
    path: '/admin', component: AdminLayout, meta: { requiresAdmin: true },
    children: [
      { path: '', name: 'admin', component: AdminDashboard, meta: { title: '数据仪表盘' } },
      { path: 'users', name: 'admin-users', component: UserManage, meta: { title: '用户管理' } },
      { path: 'reviews', name: 'admin-reviews', component: NoteReview, meta: { title: '美食笔记审核' } },
      { path: 'categories', name: 'admin-categories', component: CategoryManage, meta: { title: '美食分类管理' } },
      { path: 'tags', name: 'admin-tags', component: TagManage, meta: { title: '热门标签管理' } },
      { path: 'comments', name: 'admin-comments', component: CommentManage, meta: { title: '评论管理' } }
    ]
  }
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
