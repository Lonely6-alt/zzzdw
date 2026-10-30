// 管理员登录态管理；admin JWT 单独存 localStorage，与普通用户 token 分开
import { ref } from 'vue'

const ADMIN_TOKEN_KEY = 'food_admin_token'

// 解析 JWT payload（仅读取 role，用于前端判断，真正的校验在后端）
function parseRole(token) {
  try {
    const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')))
    return payload.role || ''
  } catch { return '' }
}

export const isAdmin = ref(false)

function sync() {
  const t = localStorage.getItem(ADMIN_TOKEN_KEY)
  isAdmin.value = !!t && parseRole(t) === 'admin'
}
sync()

export function getAdminToken() {
  const t = localStorage.getItem(ADMIN_TOKEN_KEY)
  return t && parseRole(t) === 'admin' ? t : null
}
export function setAdminToken(t) {
  localStorage.setItem(ADMIN_TOKEN_KEY, t)
  sync()
}
export function clearAdminToken() {
  localStorage.removeItem(ADMIN_TOKEN_KEY)
  sync()
}

// 管理员登录：复用 /api/login，后端返回 role，非 admin 拒绝
export async function adminLogin({ username, password }) {
  const r = await fetch('/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password })
  })
  const data = await r.json().catch(() => ({}))
  if (!r.ok) throw new Error(data.message || '登录失败')
  if (data.user?.role !== 'admin') throw new Error('该账号不是管理员')
  setAdminToken(data.token)
  return data
}

// 带管理员 token 的请求封装；401 时自动清除本地登录态
export async function adminFetch(url, options = {}) {
  const token = getAdminToken()
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) }
  if (token) headers.Authorization = `Bearer ${token}`
  const r = await fetch(url, { ...options, headers })
  if (r.status === 401) clearAdminToken()
  const data = await r.json().catch(() => ({}))
  if (!r.ok) throw new Error(data.message || `请求失败(${r.status})`)
  return data
}
