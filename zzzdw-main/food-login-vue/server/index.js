import express from 'express'
import cors from 'cors'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const DATA_DIR = path.join(__dirname, 'data')
const USERS_FILE = path.join(DATA_DIR, 'users.json')
const POSTS_FILE = path.join(DATA_DIR, 'posts.json')
const CATS_FILE = path.join(DATA_DIR, 'categories.json')
const TAGS_FILE = path.join(DATA_DIR, 'tags.json')
const COMMENTS_FILE = path.join(DATA_DIR, 'comments.json')
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

// ---------- 种子数据 ----------
const SEED_POSTS = [
  { id: 1, title: '巷子里的无名拉面', category: '面食控', author: '吃货小王', emoji: '🍜', status: 'approved',
    content: '汤头熬了 8 小时，叉烧入口即化，加一份溏心蛋绝了。藏在老小区里，工作日中午要排队。',
    createdAt: '2026-09-10T10:00:00Z' },
  { id: 2, title: '酸汤刀削面', category: '面食控', author: '面痴阿哲', emoji: '🥣', status: 'approved',
    content: '师傅现削现煮，面片厚薄不一反而更有嚼劲。酸汤里藏着十几种香料，酸得人精神一振，再加一勺油泼辣子，香得冒烟。',
    createdAt: '2026-09-16T11:20:00Z' },
  { id: 3, title: '荠菜鲜肉小馄饨', category: '面食控', author: '阿婆的邻居', emoji: '🥟', status: 'approved',
    content: '皮薄得能看见馅，一口一个。汤里只放葱花和一点猪油，鲜得很干净，早餐来一碗整个人都醒了。',
    createdAt: '2026-09-22T08:05:00Z' },
  { id: 4, title: '过早必点的武汉热干面', category: '面食控', author: '江城浪子', emoji: '🍝', status: 'approved',
    content: '芝麻酱要现磨的才香，拌开时那股酱香直冲鼻子。再加一勺辣萝卜丁和葱花，配一碗蛋酒，这才是本地人雷打不动的过早仪式。',
    createdAt: '2026-09-27T07:40:00Z' },
  { id: 5, title: '一清二白的兰州牛肉面', category: '面食控', author: '西北风', emoji: '🍲', status: 'approved',
    content: '一清二白三红四绿，汤清味厚。面条现场点单现场拉，二细最稳妥，牛肉片薄得透光，加一份卤蛋刚刚好。',
    createdAt: '2026-10-02T12:10:00Z' },

  { id: 6, title: '一人食寿司拼盘', category: '日料局', author: 'mio', emoji: '🍣', status: 'approved',
    content: '三文鱼、甜虾、鳗鱼各来一点，性价比很高。吧台位能看到师傅现切，很治愈。',
    createdAt: '2026-09-11T12:30:00Z' },
  { id: 7, title: '深夜烧鸟小酒馆', category: '日料局', author: '微醺的猫', emoji: '🍢', status: 'approved',
    content: '鸡皮烤到焦脆，鸡腿肉还锁着汁水。撒一点柚子胡椒，配一杯冰生啤，加班攒下的坏情绪全被治愈。',
    createdAt: '2026-09-18T21:50:00Z' },
  { id: 8, title: '炭火鳗鱼饭定食', category: '日料局', author: '关西小分队', emoji: '🍱', status: 'approved',
    content: '炭火现烤，前后刷了三次酱汁，鱼皮微焦、鱼肉绵密。米饭吸饱了酱汁，最后再用茶泡饭收尾刚刚好。',
    createdAt: '2026-09-25T18:15:00Z' },
  { id: 9, title: '天妇罗荞麦面', category: '日料局', author: '冷面爱好者', emoji: '🍤', status: 'approved',
    content: '荞麦面过冰水后弹牙，蘸汁清爽不咸。炸虾天妇罗脆到掉渣，记得趁热先吃天妇罗再吃面。',
    createdAt: '2026-10-04T13:25:00Z' },

  { id: 10, title: '深夜炸鸡快乐水', category: '汉堡炸鸡', author: '夜猫子', emoji: '🍔', status: 'approved',
    content: '外脆里嫩，配上冰可乐。加班后的续命神器，建议趁热吃。',
    createdAt: '2026-09-12T22:10:00Z' },
  { id: 11, title: '双层芝士牛堡', category: '汉堡炸鸡', author: '肉食动物', emoji: '🍔', status: 'approved',
    content: '肉饼现煎到边缘焦香，两片芝士拉丝能拉半米。酸黄瓜是点睛之笔，解腻又提味，配洋葱圈更过瘾。',
    createdAt: '2026-09-19T19:30:00Z' },
  { id: 12, title: '韩式甜辣炸鸡', category: '汉堡炸鸡', author: '追剧搭子', emoji: '🍗', status: 'approved',
    content: '甜辣酱裹得很均匀，撒上白芝麻和花生碎。配一份腌萝卜，一半原味一半甜辣，追剧时最上头。',
    createdAt: '2026-09-28T20:45:00Z' },
  { id: 13, title: '松露薯条', category: '汉堡炸鸡', author: '薯条星人', emoji: '🍟', status: 'approved',
    content: '现切粗薯条，撒松露盐和帕玛森芝士碎，香到舔手指。等主餐的间隙最容易一整盘见底。',
    createdAt: '2026-10-06T17:35:00Z' },

  { id: 14, title: '牛油果鸡胸轻食碗', category: '轻食沙拉', author: '健身的鹿', emoji: '🥗', status: 'approved',
    content: '低卡又顶饱，油醋汁调得刚刚好，减脂期也能吃得很满足。',
    createdAt: '2026-09-13T09:15:00Z' },
  { id: 15, title: '藜麦能量碗', category: '轻食沙拉', author: '增肌的小马', emoji: '🥙', status: 'approved',
    content: '藜麦、鹰嘴豆、烤南瓜再加一颗溏心蛋，蛋白和碳水都齐了。吃完有种「今天也没白练」的踏实感。',
    createdAt: '2026-09-21T12:00:00Z' },
  { id: 16, title: '羽衣甘蓝果昔', category: '轻食沙拉', author: '绿野', emoji: '🥤', status: 'approved',
    content: '香蕉和菠萝把菜味压得很好，一杯下肚蔬菜配额轻松达标。清爽不齁，运动后喝正合适。',
    createdAt: '2026-09-30T16:20:00Z' },
  { id: 17, title: '三文鱼波奇饭', category: '轻食沙拉', author: '夏威夷风', emoji: '🍚', status: 'approved',
    content: '生鱼丁拌上酱油和芝麻油，铺在温热米饭上，再撒海苔碎和牛油果。清爽又有饱腹感，夏天午餐的最优解。',
    createdAt: '2026-10-08T12:45:00Z' },

  { id: 18, title: '海盐芝士蛋糕', category: '甜品时间', author: '甜牙齿', emoji: '🍰', status: 'approved',
    content: '不齁甜，芝士味很浓，配一杯美式刚刚好。店员说用的是北海道奶油。',
    createdAt: '2026-09-14T15:40:00Z' },
  { id: 19, title: '抹茶大福', category: '甜品时间', author: '抹茶控', emoji: '🍡', status: 'approved',
    content: '手打糯米皮软糯拉丝，咬开是爆浆抹茶馅。微苦回甘，一次吃两个也不会觉得腻。',
    createdAt: '2026-09-23T14:10:00Z' },
  { id: 20, title: '现烤熔岩巧克力', category: '甜品时间', author: '巧克力星球', emoji: '🍫', status: 'approved',
    content: '切开时巧克力像岩浆一样涌出来。配一球香草冰淇淋，冷热交错的口感很上头，建议两个人分着吃。',
    createdAt: '2026-10-01T19:05:00Z' },
  { id: 21, title: '会晃的舒芙蕾松饼', category: '甜品时间', author: '云朵收藏家', emoji: '🥞', status: 'approved',
    content: '现点现做要等 15 分钟。蓬松得像云，端上桌还会轻轻晃。淋上枫糖浆和淡奶油，甜得很温柔。',
    createdAt: '2026-10-09T15:30:00Z' },

  { id: 22, title: '手冲耶加雪菲', category: '咖啡馆', author: '豆子控', emoji: '☕', status: 'approved',
    content: '明亮的柑橘酸调，回甘干净。店里很安静，适合带本书坐一下午。',
    createdAt: '2026-09-15T11:05:00Z' },
  { id: 23, title: '燕麦拿铁', category: '咖啡馆', author: '拿铁星人', emoji: '🥛', status: 'approved',
    content: '燕麦奶把咖啡的苦压得更圆润，入口是坚果和谷物的香。拉花是只胖天鹅，好看得舍不得搅开。',
    createdAt: '2026-09-24T09:50:00Z' },
  { id: 24, title: '焙茶拿铁', category: '咖啡馆', author: '慢煮茶铺', emoji: '🍵', status: 'approved',
    content: '焙茶香气沉稳，奶味不抢戏。午后一杯刚刚好，再配一块戚风蛋糕，就是一个完美的下午。',
    createdAt: '2026-10-03T14:40:00Z' },
  { id: 25, title: '焦糖玛奇朵', category: '咖啡馆', author: '靠窗座位', emoji: '🍮', status: 'approved',
    content: '焦糖在杯壁慢慢化开，先甜后苦层次分明。靠窗位光线好，WiFi 也很稳，续杯毫无压力。',
    createdAt: '2026-10-11T16:00:00Z' },

  { id: 26, title: '炭烤厚切五花肉', category: '烧烤夜宵', author: '夜宵团长', emoji: '🍖', status: 'approved',
    content: '肥瘦相间的五花在炭火上滋滋冒油，边缘烤到焦脆。用生菜卷上蒜片和辣酱，一口一个满足。',
    createdAt: '2026-09-17T22:30:00Z' },
  { id: 27, title: '蒜香烤生蚝', category: '烧烤夜宵', author: '海边来的', emoji: '🦪', status: 'approved',
    content: '生蚝现开现烤，铺满蒜蓉和小米辣。汁水在壳里咕嘟咕嘟，趁热吸一口最鲜，配冰啤绝配。',
    createdAt: '2026-10-05T21:15:00Z' },
  { id: 28, title: '一把烤串配冰啤', category: '烧烤夜宵', author: '撸串老手', emoji: '🍢', status: 'approved',
    content: '羊肉串要肥瘦穿插，撒足孜然和辣椒面。坐在路边的小马扎上，配一瓶冰镇啤酒，夏天才算完整。',
    createdAt: '2026-10-12T22:05:00Z' },

  { id: 29, title: '山城牛油老火锅', category: '火锅江湖', author: '无辣不欢', emoji: '🍲', status: 'approved',
    content: '牛油锅底翻滚着红汤，毛肚七上八下十五秒。配一碟蒜泥香油，辣到冒汗也停不下来。',
    createdAt: '2026-09-26T19:20:00Z' },
  { id: 30, title: '番茄牛肉锅', category: '火锅江湖', author: '养生派', emoji: '🍅', status: 'approved',
    content: '番茄熬到起沙，汤底酸甜浓稠，先喝汤再涮肉。牛肉涮八秒即可，嫩滑得几乎不用嚼。',
    createdAt: '2026-10-07T18:50:00Z' },
  { id: 31, title: '潮汕牛肉火锅', category: '火锅江湖', author: '手打牛肉丸', emoji: '🥩', status: 'approved',
    content: '吊龙、匙柄、五花趾按部位分开涮，每个部位都有最佳秒数。牛肉丸手打弹牙，据说能弹到桌上。',
    createdAt: '2026-10-13T19:40:00Z' },

  // 一条待审核的笔记，用于演示「美食笔记审核」队列
  { id: 32, title: '（待审核）巷尾新开的螺蛳粉', category: '火锅江湖', author: '嗦粉星人', emoji: '🍜', status: 'pending',
    content: '闻着臭吃着香，酸笋给得很足，汤底浓郁。第一次来可能会被味道劝退，但第二口就真香了。',
    createdAt: '2026-10-27T09:30:00Z' }
]

const CATS_META = {
  '面食控':   { icon: '🍜', bg: 'linear-gradient(140deg,#fff5e8,#ffdfba)' },
  '日料局':   { icon: '🍣', bg: 'linear-gradient(140deg,#eaf4ff,#c9e2ff)' },
  '汉堡炸鸡': { icon: '🍔', bg: 'linear-gradient(140deg,#fff9e2,#ffe1a3)' },
  '轻食沙拉': { icon: '🥗', bg: 'linear-gradient(140deg,#eafaf0,#c8efd6)' },
  '甜品时间': { icon: '🍰', bg: 'linear-gradient(140deg,#fff2f9,#ffd4e8)' },
  '咖啡馆':   { icon: '☕', bg: 'linear-gradient(140deg,#f4efff,#dbcdff)' },
  '烧烤夜宵': { icon: '🍢', bg: 'linear-gradient(140deg,#ffeee7,#ffd0ba)' },
  '火锅江湖': { icon: '🍲', bg: 'linear-gradient(140deg,#fff2ef,#ffcdc3)' }
}
const SEED_CATS = Object.entries(CATS_META).map(([name, v]) => ({ name, icon: v.icon, bg: v.bg }))
const SEED_TAGS = [
  { name: '火锅', heat: 128 }, { name: '拉面', heat: 96 }, { name: '寿司', heat: 84 },
  { name: '奶茶', heat: 77 }, { name: '烧烤', heat: 65 }, { name: '甜品', heat: 58 },
  { name: '咖啡', heat: 51 }, { name: '轻食', heat: 43 }
]
const SEED_COMMENTS = [
  { id: 1, postId: 1, author: '夜归人', rating: 5, comment: '汤头真的绝，连喝三碗。', at: '2026-09-11T12:00:00Z' },
  { id: 2, postId: 6, author: '甜虾控', rating: 5, comment: '甜虾新鲜，性价比很高。', at: '2026-09-12T13:00:00Z' },
  { id: 3, postId: 18, author: '芝士脑袋', rating: 4, comment: '不太甜，刚好。', at: '2026-09-15T16:00:00Z' },
  { id: 4, postId: 10, author: '追剧党', rating: 5, comment: '快乐水名不虚传。', at: '2026-09-13T22:30:00Z' },
  { id: 5, postId: 22, author: '豆子控', rating: 4, comment: '柑橘酸调很干净。', at: '2026-09-16T11:30:00Z' }
]

// ---------- 数据初始化 ----------
function loadPosts() {
  let posts = readJson(POSTS_FILE, null)
  if (!posts) { writeJson(POSTS_FILE, SEED_POSTS); return [...SEED_POSTS] }
  // 兼容：补齐 status 字段（旧数据默认已通过）
  let changed = false
  posts = posts.map(p => {
    if (!p.status) { changed = true; return { ...p, status: 'approved' } }
    return p
  })
  // 首次演示：确保至少有一条待审核笔记（不覆盖用户数据，动态取最大 id+1 避免冲突）
  if (!posts.some(p => p.status === 'pending')) {
    const maxId = posts.reduce((m, p) => Math.max(m, p.id || 0), 0)
    posts.push({
      id: maxId + 1,
      title: '（待审核）巷尾新开的螺蛳粉', category: '火锅江湖', author: '嗦粉星人', emoji: '🍜',
      status: 'pending',
      content: '闻着臭吃着香，酸笋给得很足，汤底浓郁。第一次来可能会被味道劝退，但第二口就真香了。',
      createdAt: '2026-10-27T09:30:00Z'
    })
    changed = true
  }
  if (changed) writeJson(POSTS_FILE, posts)
  return posts
}

function loadUsers() {
  let users = readJson(USERS_FILE, null)
  if (!users) users = {}
  let changed = false
  for (const u of Object.values(users)) {
    if (!u.role) { u.role = 'user'; changed = true }
    if (!u.status) { u.status = 'active'; changed = true }
    if (!u.createdAt) { u.createdAt = new Date().toISOString(); changed = true }
  }
  // 种子管理员账号
  if (!users.admin) {
    users.admin = {
      passwordHash: bcrypt.hashSync('admin123', 10),
      role: 'admin', status: 'active', createdAt: new Date().toISOString()
    }
    changed = true
  }
  if (changed) writeJson(USERS_FILE, users)
  return users
}

function loadCats() {
  const cats = readJson(CATS_FILE, null)
  if (!cats) { writeJson(CATS_FILE, SEED_CATS); return [...SEED_CATS] }
  return cats
}
function loadTags() {
  const tags = readJson(TAGS_FILE, null)
  if (!tags) { writeJson(TAGS_FILE, SEED_TAGS); return [...SEED_TAGS] }
  return tags
}
function loadComments() {
  const c = readJson(COMMENTS_FILE, null)
  if (!c) { writeJson(COMMENTS_FILE, SEED_COMMENTS); return [...SEED_COMMENTS] }
  return c
}

// 启动时确保种子数据落地
loadPosts(); loadUsers(); loadCats(); loadTags(); loadComments()

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
// 管理员鉴权
function adminAuth(req, res, next) {
  const h = req.headers.authorization || ''
  const token = h.startsWith('Bearer ') ? h.slice(7) : ''
  try {
    const p = jwt.verify(token, SECRET)
    if (p.role !== 'admin') return res.status(403).json({ message: '无管理员权限' })
    req.admin = p
    next()
  } catch { res.status(401).json({ message: '请先以管理员身份登录' }) }
}

// 用户对象 -> 安全列表（隐藏密码）
function userList() {
  const users = loadUsers()
  return Object.entries(users).map(([username, u]) => ({
    username, role: u.role || 'user', status: u.status || 'active', createdAt: u.createdAt
  }))
}

// ---------- 图片验证码（SVG，无需第三方依赖）----------
const captchaStore = new Map() // captchaId -> { code, expires }
const CAPTCHA_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789' // 去掉易混淆字符
const randInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min
const randColor = () => `hsl(${randInt(0, 360)}, ${randInt(55, 85)}%, ${randInt(35, 55)}%)`

function makeImageCaptcha() {
  const code = Array.from({ length: 4 }, () => CAPTCHA_CHARS[randInt(0, CAPTCHA_CHARS.length - 1)]).join('')
  const W = 130, H = 46
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">`
  svg += `<rect width="${W}" height="${H}" fill="#eef3ff"/>`
  for (let i = 0; i < 36; i++) {
    svg += `<circle cx="${randInt(0, W)}" cy="${randInt(0, H)}" r="${randInt(1, 2)}" fill="${randColor()}" opacity="0.35"/>`
  }
  for (let i = 0; i < 3; i++) {
    svg += `<line x1="0" y1="${randInt(0, H)}" x2="${W}" y2="${randInt(0, H)}" stroke="${randColor()}" stroke-width="1" opacity="0.3"/>`
  }
  const step = W / (code.length + 1)
  for (let i = 0; i < code.length; i++) {
    const x = step * (i + 1)
    const y = H / 2 + randInt(-6, 6)
    const rot = randInt(-28, 28)
    const size = randInt(24, 32)
    svg += `<text x="${x}" y="${y}" font-family="Arial, sans-serif" font-size="${size}" font-weight="bold" fill="${randColor()}" text-anchor="middle" transform="rotate(${rot} ${x} ${y})">${code[i]}</text>`
  }
  svg += `</svg>`
  const id = crypto.randomUUID()
  captchaStore.set(id, { code, expires: Date.now() + 5 * 60 * 1000 })
  return { id, image: 'data:image/svg+xml;base64,' + Buffer.from(svg).toString('base64') }
}

app.get('/api/captcha', (req, res) => {
  res.json(makeImageCaptcha())
})

// ---------- 用户：注册 / 登录 / 当前 ----------
app.post('/api/register', (req, res) => {
  const { username, password, captchaId, captcha } = req.body || {}
  if (!username || username.length < 3) return res.status(400).json({ message: '用户名至少 3 个字符' })
  if (!password || password.length !== 8) return res.status(400).json({ message: '密码必须为 8 位' })

  if (!captchaId || !captcha) return res.status(400).json({ message: '请填写图片验证码' })
  const cap = captchaStore.get(captchaId)
  if (!cap) return res.status(400).json({ message: '验证码已失效，请点击图片刷新' })
  if (cap.expires < Date.now()) { captchaStore.delete(captchaId); return res.status(400).json({ message: '验证码已过期，请点击图片刷新' }) }
  if (cap.code.toUpperCase() !== String(captcha).trim().toUpperCase()) {
    captchaStore.delete(captchaId)
    return res.status(400).json({ message: '图片验证码不正确' })
  }
  captchaStore.delete(captchaId)

  const users = loadUsers()
  if (users[username]) return res.status(409).json({ message: '该用户名已存在' })

  users[username] = {
    passwordHash: bcrypt.hashSync(password, 10),
    role: 'user', status: 'active', createdAt: new Date().toISOString()
  }
  writeJson(USERS_FILE, users)

  const token = jwt.sign({ username, role: 'user' }, SECRET, { expiresIn: '7d' })
  res.json({ token, user: { username, role: 'user' } })
})

app.post('/api/login', (req, res) => {
  const { username, password } = req.body || {}
  if (!username || !password) return res.status(400).json({ message: '请输入用户名和密码' })
  const users = loadUsers()
  const u = users[username]
  if (!u || !bcrypt.compareSync(password, u.passwordHash)) {
    return res.status(401).json({ message: '用户名或密码不正确' })
  }
  if (u.status === 'disabled') return res.status(403).json({ message: '该账号已被禁用，请联系管理员' })
  const role = u.role || 'user'
  const token = jwt.sign({ username, role }, SECRET, { expiresIn: '7d' })
  res.json({ token, user: { username, role } })
})

app.get('/api/me', auth, (req, res) => {
  const users = loadUsers()
  const u = users[req.user.username]
  if (!u) return res.status(404).json({ message: '用户不存在' })
  res.json({ user: { username: req.user.username, role: u.role || 'user' } })
})

// ---------- 美食帖子：列表（仅已通过）/ 详情 / 发布（待审核）----------
app.get('/api/posts', (req, res) => {
  const posts = loadPosts()
  const list = posts.filter(p => p.status === 'approved')
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
    title, category, content,
    emoji: emoji || '🍴',
    author: req.user.username,
    status: 'pending', // 新发布的笔记需管理员审核
    createdAt: new Date().toISOString()
  }
  posts.push(post)
  writeJson(POSTS_FILE, posts)
  res.status(201).json(post)
})

// ---------- 评论：公开读取 / 发布（后端持久化）----------
app.get('/api/comments', (req, res) => {
  res.json(loadComments().sort((a, b) => b.id - a.id))
})

app.post('/api/posts/:id/comments', auth, (req, res) => {
  const { author, rating, comment } = req.body || {}
  const postId = Number(req.params.id)
  if (!comment || !comment.trim()) return res.status(400).json({ message: '评论内容不能为空' })
  const comments = loadComments()
  const entry = {
    id: comments.reduce((m, c) => Math.max(m, c.id), 0) + 1,
    postId,
    author: author || req.user.username || '匿名',
    rating: Number(rating) || 5,
    comment: String(comment).trim(),
    at: new Date().toISOString()
  }
  comments.push(entry)
  writeJson(COMMENTS_FILE, comments)
  res.status(201).json(entry)
})

// ====================================================================
//  后台管理接口（均需要管理员 token）
// ====================================================================

// 数据仪表盘统计
app.get('/api/admin/stats', adminAuth, (req, res) => {
  const users = userList()
  const posts = loadPosts()
  const comments = loadComments()
  const cats = loadCats()
  const tags = loadTags()
  res.json({
    users: users.length,
    usersActive: users.filter(u => u.status === 'active').length,
    posts: posts.length,
    postsPending: posts.filter(p => p.status === 'pending').length,
    postsApproved: posts.filter(p => p.status === 'approved').length,
    comments: comments.length,
    categories: cats.length,
    tags: tags.length
  })
})

// 用户管理
app.get('/api/admin/users', adminAuth, (req, res) => {
  res.json(userList())
})
app.post('/api/admin/users', adminAuth, (req, res) => {
  const { username, password, role } = req.body || {}
  if (!username || username.length < 3) return res.status(400).json({ message: '用户名至少 3 个字符' })
  if (!password || password.length < 6) return res.status(400).json({ message: '密码至少 6 位' })
  const users = loadUsers()
  if (users[username]) return res.status(409).json({ message: '该用户名已存在' })
  users[username] = {
    passwordHash: bcrypt.hashSync(password, 10),
    role: role === 'admin' ? 'admin' : 'user',
    status: 'active', createdAt: new Date().toISOString()
  }
  writeJson(USERS_FILE, users)
  res.status(201).json({ username, role: users[username].role, status: 'active' })
})
app.patch('/api/admin/users/:username', adminAuth, (req, res) => {
  const { username } = req.params
  const { status, role } = req.body || {}
  const users = loadUsers()
  const u = users[username]
  if (!u) return res.status(404).json({ message: '用户不存在' })
  if (status) u.status = status === 'disabled' ? 'disabled' : 'active'
  if (role) u.role = role === 'admin' ? 'admin' : 'user'
  writeJson(USERS_FILE, users)
  res.json({ username, role: u.role, status: u.status })
})
app.delete('/api/admin/users/:username', adminAuth, (req, res) => {
  const { username } = req.params
  const users = loadUsers()
  if (!users[username]) return res.status(404).json({ message: '用户不存在' })
  if (users[username].role === 'admin') return res.status(400).json({ message: '管理员账号不可删除' })
  delete users[username]
  writeJson(USERS_FILE, users)
  res.json({ ok: true })
})

// 美食笔记审核
app.get('/api/admin/posts', adminAuth, (req, res) => {
  const posts = loadPosts()
  const { status } = req.query
  const list = status ? posts.filter(p => p.status === status) : posts
  res.json(list.sort((a, b) => b.id - a.id))
})
app.patch('/api/admin/posts/:id', adminAuth, (req, res) => {
  const { id } = req.params
  const { status } = req.body || {}
  if (!['approved', 'rejected', 'pending'].includes(status)) {
    return res.status(400).json({ message: '非法的审核状态' })
  }
  const posts = loadPosts()
  const post = posts.find(p => p.id === Number(id))
  if (!post) return res.status(404).json({ message: '笔记不存在' })
  post.status = status
  writeJson(POSTS_FILE, posts)
  res.json(post)
})
app.delete('/api/admin/posts/:id', adminAuth, (req, res) => {
  const { id } = req.params
  const posts = loadPosts()
  const idx = posts.findIndex(p => p.id === Number(id))
  if (idx === -1) return res.status(404).json({ message: '笔记不存在' })
  posts.splice(idx, 1)
  writeJson(POSTS_FILE, posts)
  res.json({ ok: true })
})

// 美食分类管理
app.get('/api/admin/categories', adminAuth, (req, res) => res.json(loadCats()))
app.post('/api/admin/categories', adminAuth, (req, res) => {
  const { name, icon, bg } = req.body || {}
  if (!name || !name.trim()) return res.status(400).json({ message: '分类名称不能为空' })
  const cats = loadCats()
  if (cats.find(c => c.name === name.trim())) return res.status(409).json({ message: '分类已存在' })
  const cat = { name: name.trim(), icon: icon || '🍽️', bg: bg || 'linear-gradient(140deg,#fdf6ee,#f3e6d6)' }
  cats.push(cat)
  writeJson(CATS_FILE, cats)
  res.status(201).json(cat)
})
app.put('/api/admin/categories/:name', adminAuth, (req, res) => {
  const { name } = req.params
  const { icon, bg } = req.body || {}
  const cats = loadCats()
  const cat = cats.find(c => c.name === name)
  if (!cat) return res.status(404).json({ message: '分类不存在' })
  if (icon) cat.icon = icon
  if (bg) cat.bg = bg
  writeJson(CATS_FILE, cats)
  res.json(cat)
})
app.delete('/api/admin/categories/:name', adminAuth, (req, res) => {
  const { name } = req.params
  const cats = loadCats()
  const idx = cats.findIndex(c => c.name === name)
  if (idx === -1) return res.status(404).json({ message: '分类不存在' })
  cats.splice(idx, 1)
  writeJson(CATS_FILE, cats)
  // 被删分类下的笔记归到「未分类」
  const posts = loadPosts()
  let changed = false
  posts.forEach(p => { if (p.category === name) { p.category = '未分类'; changed = true } })
  if (changed) writeJson(POSTS_FILE, posts)
  res.json({ ok: true })
})

// 热门标签管理
app.get('/api/admin/tags', adminAuth, (req, res) => res.json(loadTags().sort((a, b) => b.heat - a.heat)))
app.post('/api/admin/tags', adminAuth, (req, res) => {
  const { name } = req.body || {}
  if (!name || !name.trim()) return res.status(400).json({ message: '标签名称不能为空' })
  const tags = loadTags()
  if (tags.find(t => t.name === name.trim())) return res.status(409).json({ message: '标签已存在' })
  const tag = { name: name.trim(), heat: 0 }
  tags.push(tag)
  writeJson(TAGS_FILE, tags)
  res.status(201).json(tag)
})
app.delete('/api/admin/tags/:name', adminAuth, (req, res) => {
  const { name } = req.params
  const tags = loadTags()
  const idx = tags.findIndex(t => t.name === name)
  if (idx === -1) return res.status(404).json({ message: '标签不存在' })
  tags.splice(idx, 1)
  writeJson(TAGS_FILE, tags)
  res.json({ ok: true })
})

// 评论管理
app.get('/api/admin/comments', adminAuth, (req, res) => {
  const posts = loadPosts()
  const titleOf = id => posts.find(p => p.id === Number(id))?.title || '（笔记已删除）'
  const list = loadComments()
    .sort((a, b) => b.id - a.id)
    .map(c => ({ ...c, postTitle: titleOf(c.postId) }))
  res.json(list)
})
app.delete('/api/admin/comments/:id', adminAuth, (req, res) => {
  const { id } = req.params
  const comments = loadComments()
  const idx = comments.findIndex(c => c.id === Number(id))
  if (idx === -1) return res.status(404).json({ message: '评论不存在' })
  comments.splice(idx, 1)
  writeJson(COMMENTS_FILE, comments)
  res.json({ ok: true })
})

app.listen(PORT, () => {
  console.log(`🍲 美食后端已启动: http://localhost:${PORT}`)
})
