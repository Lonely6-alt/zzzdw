import express from 'express'
import cors from 'cors'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const DATA_DIR = path.join(__dirname, 'data')
const USERS_FILE = path.join(DATA_DIR, 'users.json')
const POSTS_FILE = path.join(DATA_DIR, 'posts.json')
const SECRET = 'food-dev-secret-change-me' // 演示用，生产请改为环境变量
const PORT = 3000

// ---------- 本地存储（JSON 文件）----------
function readJson(file, fallback) {
  try { return JSON.parse(fs.readFileSync(file, 'utf-8')) } catch { return fallback }
}
function writeJson(file, data) {
  fs.mkdirSync(DATA_DIR, { recursive: true })
  fs.writeFileSync(file, JSON.stringify(data, null, 2))
}

const SEED_POSTS = [
  { id: 1, title: '巷子里的无名拉面', category: '面食控', author: '吃货小王', emoji: '🍜',
    content: '汤头熬了 8 小时，叉烧入口即化，加一份溏心蛋绝了。藏在老小区里，工作日中午要排队。',
    createdAt: '2026-09-10T10:00:00Z' },
  { id: 2, title: '一人食寿司拼盘', category: '日料局', author: 'mio', emoji: '🍣',
    content: '三文鱼、甜虾、鳗鱼各来一点，性价比很高。吧台位能看到师傅现切，很治愈。',
    createdAt: '2026-09-11T12:30:00Z' },
  { id: 3, title: '深夜炸鸡快乐水', category: '汉堡炸鸡', author: '夜猫子', emoji: '🍔',
    content: '外脆里嫩，配上冰可乐。加班后的续命神器，建议趁热吃。',
    createdAt: '2026-09-12T22:10:00Z' },
  { id: 4, title: '牛油果鸡胸轻食碗', category: '轻食沙拉', author: '健身的鹿', emoji: '🥗',
    content: '低卡又顶饱，油醋汁调得刚刚好，减脂期也能吃得很满足。',
    createdAt: '2026-09-13T09:15:00Z' },
  { id: 5, title: '海盐芝士蛋糕', category: '甜品时间', author: '甜牙齿', emoji: '🍰',
    content: '不齁甜，芝士味很浓，配一杯美式刚刚好。店员说用的是北海道奶油。',
    createdAt: '2026-09-14T15:40:00Z' },
  { id: 6, title: '手冲耶加雪菲', category: '咖啡馆', author: '豆子控', emoji: '☕',
    content: '明亮的柑橘酸调，回甘干净。店里很安静，适合带本书坐一下午。',
    createdAt: '2026-09-15T11:05:00Z' }
]

function loadPosts() {
  const posts = readJson(POSTS_FILE, null)
  if (!posts) { writeJson(POSTS_FILE, SEED_POSTS); return SEED_POSTS }
  return posts
}

const app = express()
app.use(cors())
app.use(express.json())

// ---------- 鉴权中间件 ----------
function auth(req, res, next) {
  const h = req.headers.authorization || ''
  const token = h.startsWith('Bearer ') ? h.slice(7) : ''
  try { req.user = jwt.verify(token, SECRET); next() }
  catch { res.status(401).json({ message: '未登录或登录已过期' }) }
}

// ---------- 用户：注册 / 登录 / 当前 ----------
app.post('/api/register', (req, res) => {
  const { username, phone, password } = req.body || {}
  if (!username || username.length < 3) return res.status(400).json({ message: '用户名至少 3 个字符' })
  if (!/^1\d{10}$/.test(phone || '')) return res.status(400).json({ message: '手机号格式不正确' })
  if (!password || password.length < 6) return res.status(400).json({ message: '密码至少 6 位' })

  const users = readJson(USERS_FILE, {})
  if (users[username]) return res.status(409).json({ message: '该用户名已存在' })

  users[username] = { phone, passwordHash: bcrypt.hashSync(password, 10) }
  writeJson(USERS_FILE, users)

  const token = jwt.sign({ username }, SECRET, { expiresIn: '7d' })
  res.json({ token, user: { username, phone } })
})

app.post('/api/login', (req, res) => {
  const { username, password } = req.body || {}
  if (!username || !password) return res.status(400).json({ message: '请输入用户名和密码' })
  const users = readJson(USERS_FILE, {})
  const u = users[username]
  if (!u || !bcrypt.compareSync(password, u.passwordHash)) {
    return res.status(401).json({ message: '用户名或密码不正确' })
  }
  const token = jwt.sign({ username }, SECRET, { expiresIn: '7d' })
  res.json({ token, user: { username, phone: u.phone } })
})

app.get('/api/me', auth, (req, res) => {
  const users = readJson(USERS_FILE, {})
  const u = users[req.user.username]
  if (!u) return res.status(404).json({ message: '用户不存在' })
  res.json({ user: { username: req.user.username, phone: u.phone } })
})

// ---------- 美食帖子：列表 / 详情 / 发布 ----------
app.get('/api/posts', (req, res) => {
  const posts = loadPosts()
  const { category } = req.query
  const list = category ? posts.filter(p => p.category === category) : posts
  res.json(list.sort((a, b) => b.id - a.id))
})

app.get('/api/posts/:id', (req, res) => {
  const posts = loadPosts()
  const post = posts.find(p => p.id === Number(req.params.id))
  if (!post) return res.status(404).json({ message: '帖子不存在' })
  res.json(post)
})

app.post('/api/posts', auth, (req, res) => {
  const { title, category, content, emoji } = req.body || {}
  if (!title || !category || !content) {
    return res.status(400).json({ message: '标题、分类、内容都不能为空' })
  }
  const posts = loadPosts()
  const id = posts.reduce((m, p) => Math.max(m, p.id), 0) + 1
  const post = {
    id,
    title,
    category,
    content,
    emoji: emoji || '🍴',
    author: req.user.username,
    createdAt: new Date().toISOString()
  }
  posts.push(post)
  writeJson(POSTS_FILE, posts)
  res.status(201).json(post)
})

app.listen(PORT, () => {
  console.log(`🍲 美食后端已启动: http://localhost:${PORT}`)
})
