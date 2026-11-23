// 菜品 / 店铺卡片元数据：多图画廊、热量标签、忌口标记、堂食/打包、
// 人均消费、营业时间与营业状态、笔记类型（种草/避雷）。
// 数据均为「确定性伪数据」：由帖子 id / 分类哈希推导，同一帖子每次展示一致，
// 不依赖后端表结构变更；真实数据接入时把对应函数替换为接口字段即可。
import { ref } from 'vue'
import { catPhoto, catBg, catIcon } from '../data/categories.js'

const NOTE_KEY = 'food_note_types'   // { [postId]: 'plant' | 'avoid' } 用户手动标记的类型
const PENDING_KEY = 'food_note_pending' // { [title]: 'plant' | 'avoid' } 刚发布还没拿到 id 的类型

/* ---------------- 小工具 ---------------- */
function hash(s) {
  let h = 0
  s = String(s ?? '')
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0
  return Math.abs(h)
}
function pick(pool, seed) { return pool[seed % pool.length] }
function readMap(key) {
  try { return JSON.parse(localStorage.getItem(key) || '{}') } catch { return {} }
}
function writeMap(key, m) { localStorage.setItem(key, JSON.stringify(m)) }

/* ---------------- 忌口标记 ---------------- */
// 分类基底：该分类大概率含有的食材标记
const CAT_MARKERS = {
  '面食控':   { meat: true },
  '日料局':   { meat: true, seafood: true },
  '汉堡炸鸡': { meat: true, dairy: true },
  '轻食沙拉': { },
  '甜品时间': { dairy: true, egg: true },
  '咖啡馆':   { dairy: true },
  '烧烤夜宵': { meat: true, spice: true },
  '火锅江湖': { meat: true, spice: true }
}
const ALL_MARKERS = ['meat', 'dairy', 'seafood', 'cilantro', 'spice', 'peanut']

/** 确定性食材标记：分类基底 + 帖子哈希抖动，同一帖子结果稳定 */
function markersOf(p) {
  const seed = hash(`${p?.id}-${p?.title}`)
  const base = { ...(CAT_MARKERS[p?.category] || {}) }
  // 每个「没有」的标记有 1/3 概率被打开（比如面食里放了香菜），制造差异
  for (const k of ALL_MARKERS) {
    if (!base[k] && seed % 3 === 0) base[k] = true
  }
  // 轻食沙拉永不算荤、咖啡店永不算海鲜，避免明显不合常理的组合
  if (p?.category === '轻食沙拉') base.meat = false
  if (p?.category === '咖啡馆') base.seafood = false
  return base
}

/** 忌口筛选定义：label 用于筛选按钮，desc 用于提示 */
export const DIET_FILTERS = [
  { key: 'vegetarian', label: '素食可吃', emoji: '🥬', test: m => !m.meat },
  { key: 'dairy', label: '蛋奶过敏可吃', emoji: '🥛', test: m => !m.dairy },
  { key: 'cilantro', label: '不含香菜', emoji: '🌿', test: m => !m.cilantro },
  { key: 'spice', label: '不吃辣', emoji: '🌶️', test: m => !m.spice },
  { key: 'seafood', label: '海鲜过敏可吃', emoji: '🦐', test: m => !m.seafood }
]

/** 某帖子对某个忌口诉求是否安全 */
function safeFor(p, concernKey) {
  const f = DIET_FILTERS.find(x => x.key === concernKey)
  if (!f || !p) return true
  return f.test(markersOf(p))
}

/** 卡片上展示的忌口标签：绿色=适合，橙色=慎点 */
function dietTagsOf(p) {
  const m = markersOf(p)
  const tags = []
  if (!m.meat && !m.seafood) tags.push({ text: '素食友好', cls: 'safe' })
  if (m.spice) tags.push({ text: '微辣 / 重辣', cls: 'warn' })
  if (m.dairy) tags.push({ text: '含蛋奶', cls: 'warn' })
  if (m.cilantro) tags.push({ text: '含香菜', cls: 'warn' })
  if (m.seafood) tags.push({ text: '含海鲜', cls: 'warn' })
  if (m.peanut) tags.push({ text: '含花生坚果', cls: 'warn' })
  if (!tags.length) tags.push({ text: '无常见忌口', cls: 'safe' })
  return tags.slice(0, 3)
}

/* ---------------- 热量标签 ---------------- */
const CAL_RANGE = {
  '面食控': [450, 750], '日料局': [300, 600], '汉堡炸鸡': [650, 950],
  '轻食沙拉': [120, 320], '甜品时间': [280, 520], '咖啡馆': [150, 380],
  '烧烤夜宵': [500, 880], '火锅江湖': [550, 900]
}
function calorieOf(p) {
  const [lo, hi] = CAL_RANGE[p?.category] || [300, 700]
  const seed = hash(`cal-${p?.id}-${p?.title}`)
  const kcal = lo + (seed % (hi - lo))
  const level = kcal < 300 ? '轻' : kcal <= 600 ? '中' : '高'
  return { kcal, level, text: `≈${kcal} kcal`, cls: kcal < 300 ? 'low' : kcal <= 600 ? 'mid' : 'high' }
}

/* ---------------- 堂食 / 打包 ---------------- */
const SERVE_POOL = ['堂食', '打包', '堂食 · 打包']
function serveOf(p) {
  return pick(SERVE_POOL, hash(`serve-${p?.id}-${p?.shopName || ''}`))
}

/* ---------------- 人均 / 营业时间 ---------------- */
function avgPriceOf(p) {
  const price = Number(p?.price)
  if (price > 0) return Math.round(price * 1.6)
  return 18 + hash(`price-${p?.id}`) % 70
}
const HOURS_POOL = [
  ['09:00', '21:30'], ['10:00', '22:00'], ['08:30', '20:30'],
  ['11:00', '23:00'], ['09:30', '21:00'], ['10:30', '22:30']
]
function hoursOf(p) {
  const shopKey = p?.shopName || p?.author || p?.id || ''
  return pick(HOURS_POOL, hash(`hours-${shopKey}`))
}
function toMin(hhmm) {
  const [h, m] = String(hhmm).split(':').map(Number)
  return (h || 0) * 60 + (m || 0)
}
/** 营业状态：营业中 / 即将打烊（距打烊≤60分钟）/ 已打烊 / 未开始 */
function openStatusOf(p, now = new Date()) {
  const [open, close] = hoursOf(p)
  const t = now.getHours() * 60 + now.getMinutes()
  const o = toMin(open), c = toMin(close)
  if (t < o) return { key: 'soon', label: '未开始', cls: 'off' }
  if (t >= c) return { key: 'closed', label: '已打烊', cls: 'off' }
  if (c - t <= 60) return { key: 'closing', label: '即将打烊', cls: 'warn' }
  return { key: 'open', label: '营业中', cls: 'on' }
}

/* ---------------- 多图画廊（轮播用） ---------------- */
const EMOJI_VARIETY = ['🥢', '🍽️', '✨', '🧄', '🫕', '🥟', '🍚', '🧅']
/**
 * 轮播图数据：实拍图(带水印) → 分类插画 → 2 张 emoji 渐变卡
 * 返回 [{ kind:'photo'|'illus'|'emoji', url?, emoji?, bg? }]
 */
function galleryOf(p) {
  const slides = []
  if (p?.imageUrl) slides.push({ kind: 'photo', url: p.imageUrl, watermark: true })
  const illus = catPhoto(p?.category)
  if (illus) slides.push({ kind: 'illus', url: illus, bg: catBg(p?.category) })
  const seed = hash(`gal-${p?.id}-${p?.title}`)
  const bg = catBg(p?.category)
  slides.push({ kind: 'emoji', emoji: p?.emoji || catIcon(p?.category), bg })
  slides.push({ kind: 'emoji', emoji: pick(EMOJI_VARIETY, seed), bg })
  return slides.slice(0, 4)
}

/* ---------------- 笔记类型：种草 / 避雷 ---------------- */
const noteTypes = ref(readMap(NOTE_KEY))
const pendingTypes = ref(readMap(PENDING_KEY))

/** 笔记类型：用户手动标记 > 刚发布的待定标记 > 评分兜底（均分<3.5 视为避雷向） */
function noteTypeOf(p) {
  if (!p) return 'plant'
  const byId = noteTypes.value[p.id]
  if (byId) return byId
  const byTitle = pendingTypes.value[p.title]
  if (byTitle) return byTitle
  const r = Number(p.rating)
  if (r > 0 && r < 3.5) return 'avoid'
  return 'plant'
}
/** 手动标记笔记类型（发布时选择 / 用户改标） */
function setNoteType(p, type) {
  if (!p) return
  if (p.id != null) {
    noteTypes.value = { ...noteTypes.value, [p.id]: type }
    writeMap(NOTE_KEY, noteTypes.value)
  }
  // 同时记录 title 键，保证刚发布、列表刷新拿到新 id 前也能命中
  if (p.title) {
    pendingTypes.value = { ...pendingTypes.value, [p.title]: type }
    writeMap(PENDING_KEY, pendingTypes.value)
  }
}

/* ---------------- 对外导出 ---------------- */
export function useFoodMeta() {
  return {
    galleryOf, calorieOf, dietTagsOf, serveOf,
    avgPriceOf, hoursOf, openStatusOf,
    safeFor, noteTypeOf, setNoteType,
    markersOf, DIET_FILTERS
  }
}
