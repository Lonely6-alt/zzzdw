// 对接后端 API 的登录态管理；JWT 存浏览器 localStorage，authUser / authRole 为全局响应式状态
import { ref } from 'vue'

const API = '/api'
const TOKEN_KEY = 'food_token'
const ROLE_KEY = 'food_role'
export const authUser = ref(localStorage.getItem(TOKEN_KEY) ? (localStorage.getItem('food_user') || '') : '')
export const authRole = ref(localStorage.getItem(ROLE_KEY) || '')

export function getToken() {
  return localStorage.getItem(TOKEN_KEY)
}
export function setToken(t) {
  localStorage.setItem(TOKEN_KEY, t)
}
export function clearToken() {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(ROLE_KEY)
  localStorage.removeItem('food_user')
}
function setRole(r) {
  authRole.value = r || ''
  if (r) localStorage.setItem(ROLE_KEY, r)
  else localStorage.removeItem(ROLE_KEY)
}
function setUser(u) {
  authUser.value = u || ''
  if (u) localStorage.setItem('food_user', u)
  else localStorage.removeItem('food_user')
}

// 注册：需携带图片验证码 captchaId + captcha
export async function apiRegister({ username, password, captchaId, captcha }) {
  const r = await fetch(`${API}/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password, captchaId, captcha })
  })
  const data = await r.json().catch(() => ({}))
  if (!r.ok) throw new Error(data.message || '注册失败')
  return data
}

// 获取图片验证码
export async function fetchCaptcha() {
  const r = await fetch(`${API}/captcha`)
  if (!r.ok) throw new Error('获取图片验证码失败')
  return r.json()
}

// 登录（返回 token 与角色）
export async function apiLogin({ username, password }) {
  const r = await fetch(`${API}/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password })
  })
  const data = await r.json().catch(() => ({}))
  if (!r.ok) throw new Error(data.message || '登录失败')
  return data
}

// 获取当前登录用户信息（含角色）
export async function apiMe() {
  const r = await fetch(`${API}/me`, { headers: { Authorization: `Bearer ${getToken()}` } })
  if (!r.ok) throw new Error('会话失效')
  return r.json()
}

// ---- 业务封装 ----
export async function login({ username, password }) {
  const d = await apiLogin({ username, password })
  setToken(d.token)
  setUser(d.user.username)
  setRole(d.user.role)
  return d
}

export async function register(payload) {
  const d = await apiRegister(payload)
  setToken(d.token)
  setUser(d.user.username)
  setRole(d.user.role)
  return d
}

export function logout() {
  clearToken()
  authUser.value = ''
  authRole.value = ''
}

// 启动时校验 token 是否有效，并同步角色
export async function ensureSession() {
  if (!getToken()) return false
  try {
    const d = await apiMe()
    setUser(d.user.username)
    setRole(d.user.role)
    return true
  } catch {
    logout()
    return false
  }
}
