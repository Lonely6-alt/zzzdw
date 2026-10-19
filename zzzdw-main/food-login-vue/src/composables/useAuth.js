// 对接后端 API 的登录态管理；JWT 存浏览器 localStorage，authUser 为全局响应式登录用户
import { ref } from 'vue'

const API = '/api'
const TOKEN_KEY = 'food_token'
export const authUser = ref('') // 当前登录用户名（空表示未登录）

export function getToken() {
  return localStorage.getItem(TOKEN_KEY)
}
export function setToken(t) {
  localStorage.setItem(TOKEN_KEY, t)
}
export function clearToken() {
  localStorage.removeItem(TOKEN_KEY)
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

// 获取图片验证码（返回 { id, image }，image 可直接用于 <img src>）
export async function fetchCaptcha() {
  const r = await fetch(`${API}/captcha`)
  if (!r.ok) throw new Error('获取图片验证码失败')
  return r.json()
}

// 登录
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

// 获取当前登录用户信息
export async function apiMe() {
  const r = await fetch(`${API}/me`, { headers: { Authorization: `Bearer ${getToken()}` } })
  if (!r.ok) throw new Error('会话失效')
  return r.json()
}

// ---- 业务封装 ----
export async function login({ username, password }) {
  const d = await apiLogin({ username, password })
  setToken(d.token)
  authUser.value = d.user.username
  return d
}

export async function register(payload) {
  const d = await apiRegister(payload)
  setToken(d.token)
  authUser.value = d.user.username
  return d
}

export function logout() {
  clearToken()
  authUser.value = ''
}

// 启动时校验 token 是否有效
export async function ensureSession() {
  if (!getToken()) return false
  try {
    const d = await apiMe()
    authUser.value = d.user.username
    return true
  } catch {
    logout()
    return false
  }
}
