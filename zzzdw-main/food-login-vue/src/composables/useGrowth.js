// 吃货成长体系：积分、等级、每周任务、优惠券、吃货徽章。
// 纯前端实现（localStorage 持久化），与 useOrder 的演示定位一致；
// 后续接后端时把 persist 部分换成接口调用即可。
import { ref, computed } from 'vue'
import { useToast } from './useToast.js'

const PT_KEY = 'food_growth_points'
const WEEK_KEY = 'food_growth_week'   // { week, progress:{}, claimed:{} }
const COUPON_KEY = 'food_growth_coupons'
const BADGE_KEY = 'food_growth_badges'
const TASTE_KEY = 'food_growth_tastes' // 口味挑战：尝试过的分类集合

/* ---------------- 等级 ---------------- */
export const LEVELS = [
  { lv: 1, name: '吃货新人', min: 0, emoji: '🐣' },
  { lv: 2, name: '干饭学徒', min: 100, emoji: '🍳' },
  { lv: 3, name: '探店达人', min: 300, emoji: '🧭' },
  { lv: 4, name: '美食评论家', min: 800, emoji: '✍️' },
  { lv: 5, name: '食神', min: 2000, emoji: '👑' }
]

/* ---------------- 每周任务 ---------------- */
export const WEEKLY_TASKS = [
  { key: 'like', title: '给 3 道美食点赞', target: 3, points: 10, emoji: '❤️' },
  { key: 'fav', title: '收藏 2 家心动小店', target: 2, points: 15, emoji: '⭐' },
  { key: 'comment', title: '发布 2 条真实评价', target: 2, points: 20, emoji: '💬' },
  { key: 'publish', title: '发布 1 篇探店笔记', target: 1, points: 30, emoji: '📝' },
  { key: 'variety', title: '打卡 2 种不同口味', target: 2, points: 25, emoji: '🌈' }
]

/* ---------------- 优惠券 ---------------- */
export const COUPON_SHOP = [
  { id: 'c5', name: '满 30 减 5 优惠券', cost: 50, emoji: '🎟️' },
  { id: 'c12', name: '满 60 减 12 优惠券', cost: 90, emoji: '🎫' },
  { id: 'c25', name: '满 100 减 25 优惠券', cost: 150, emoji: '🧧' }
]

/* ---------------- 吃货徽章 ---------------- */
export const BADGES = [
  // 探店系
  { id: 'explore1', group: '探店', emoji: '🥾', name: '初出茅庐', desc: '发布第 1 篇探店笔记', check: s => s.publish >= 1 },
  { id: 'explore5', group: '探店', emoji: '🧭', name: '探店老手', desc: '累计发布 5 篇笔记', check: s => s.publish >= 5 },
  { id: 'explore10', group: '探店', emoji: '🗺️', name: '探店大师', desc: '累计发布 10 篇笔记', check: s => s.publish >= 10 },
  // 打卡系
  { id: 'checkin1', group: '打卡', emoji: '📍', name: '打卡新秀', desc: '发布第 1 条美食评价', check: s => s.comment >= 1 },
  { id: 'checkin10', group: '打卡', emoji: '🖊️', name: '点评达人', desc: '累计发布 10 条评价', check: s => s.comment >= 10 },
  { id: 'checkin25', group: '打卡', emoji: '👑', name: '美食评论家', desc: '累计发布 25 条评价', check: s => s.comment >= 25 },
  // 口味挑战系
  { id: 'taste3', group: '口味挑战', emoji: '👅', name: '味蕾开拓者', desc: '尝试 3 种不同口味分类', check: s => s.tastes >= 3 },
  { id: 'taste6', group: '口味挑战', emoji: '🌈', name: '全口味通', desc: '尝试 6 种不同口味分类', check: s => s.tastes >= 6 },
  { id: 'taste8', group: '口味挑战', emoji: '🏆', name: '百味挑战王', desc: '尝遍全站 8 种分类', check: s => s.tastes >= 8 },
  // 收藏系
  { id: 'fav5', group: '收藏', emoji: '⭐', name: '心动收藏家', desc: '收藏 5 道美食', check: s => s.fav >= 5 },
  { id: 'fav15', group: '收藏', emoji: '💎', name: '私藏地图', desc: '收藏 15 道美食', check: s => s.fav >= 15 }
]

/* ---------------- 持久化状态 ---------------- */
function readInt(key, d = 0) { const v = parseInt(localStorage.getItem(key), 10); return Number.isFinite(v) ? v : d }
function weekKey() {
  const d = new Date()
  // 简化 ISO 周：以当年第几周为键，周一为起点（getDay 周一=1）
  const start = new Date(d.getFullYear(), 0, 1)
  const week = Math.floor((d - start) / (7 * 864e5)) + 1
  return `${d.getFullYear()}-W${week}`
}

const points = ref(readInt(PT_KEY))
const coupons = ref(readJson(COUPON_KEY))
const unlocked = ref(readJson(BADGE_KEY))
const tastes = ref(readJson(TASTE_KEY))       // { 分类名: true }
const week = ref(readJson(WEEK_KEY))
if (week.value.week !== weekKey()) week.value = { week: weekKey(), progress: {}, claimed: {} }

function readJson(key) {
  try { return JSON.parse(localStorage.getItem(key) || '{}') } catch { return {} }
}
function persist() {
  localStorage.setItem(PT_KEY, String(points.value))
  localStorage.setItem(COUPON_KEY, JSON.stringify(coupons.value))
  localStorage.setItem(BADGE_KEY, JSON.stringify(unlocked.value))
  localStorage.setItem(TASTE_KEY, JSON.stringify(tastes.value))
  localStorage.setItem(WEEK_KEY, JSON.stringify(week.value))
}

/* ---------------- 等级计算 ---------------- */
const level = computed(() => {
  let cur = LEVELS[0]
  for (const l of LEVELS) if (points.value >= l.min) cur = l
  return cur
})
const nextLevel = computed(() => LEVELS.find(l => l.min > points.value) || null)
const levelProgress = computed(() => {
  if (!nextLevel.value) return 1
  const cur = level.value
  return (points.value - cur.min) / (nextLevel.value.min - cur.min)
})

/* ---------------- 统计快照（徽章判定用） ---------------- */
const stats = ref(readJson('food_growth_stats')) // { publish, comment, fav, like }
function bumpStats(k, n = 1) {
  stats.value = { ...stats.value, [k]: (stats.value[k] || 0) + n }
}

/* ---------------- 行为入口：各页面 / 组合式函数统一调用 ---------------- */
let initialized = false

function checkBadges() {
  const newly = []
  for (const b of BADGES) {
    if (!unlocked.value[b.id] && b.check({
      publish: stats.value.publish || 0,
      comment: stats.value.comment || 0,
      fav: stats.value.fav || 0,
      like: stats.value.like || 0,
      tastes: Object.keys(tastes.value).length
    })) {
      unlocked.value = { ...unlocked.value, [b.id]: Date.now() }
      newly.push(b)
    }
  }
  if (newly.length) {
    persist()
    for (const b of newly) useToast().toast(`🎖️ 解锁徽章「${b.name}」！`, 'success')
  }
}

/**
 * 行为上报（点赞/收藏/评价/发笔记都从这里走）：
 * type: 'like' | 'fav' | 'comment' | 'publish'，meta: { category }
 */
function onAction(type, meta = {}) {
  const PT = { like: 2, fav: 5, comment: 10, publish: 20 }
  const TASK_MAP = { like: 'like', fav: 'fav', comment: 'comment', publish: 'publish' }

  const gain = PT[type]
  if (gain) {
    points.value += gain
    toastMaybe(`+${gain} 吃货积分`)
  }
  if (type === 'like') bumpStats('like')
  if (type === 'fav') bumpStats('fav')
  if (type === 'comment') bumpStats('comment')
  if (type === 'publish') bumpStats('publish')

  // 口味挑战：发布/评价时记录尝试过的分类
  const taskKey = TASK_MAP[type]
  if (taskKey && meta.category) {
    if (!tastes.value[meta.category]) {
      tastes.value = { ...tastes.value, [meta.category]: Date.now() }
      const before = Object.keys(tastes.value).length
      toastMaybe(`🌈 新口味解锁：${meta.category}（已尝试 ${before} 种）`)
      // variety 任务：每解锁一个新口味计 1
      incTask('variety')
    }
  }
  if (taskKey) incTask(taskKey)

  checkBadges()
  persist()
}

function incTask(key) {
  const t = WEEKLY_TASKS.find(x => x.key === key)
  if (!t) return
  const w = week.value
  if (w.week !== weekKey()) { week.value = { week: weekKey(), progress: {}, claimed: {} }; return }
  const cur = w.progress[key] || 0
  if (cur >= t.target) return
  w.progress = { ...w.progress, [key]: cur + 1 }
}

function toastMaybe(msg) {
  // 静默积分提示太频繁会打扰，只在关键节点（等级提升 / 解锁）由 checkBadges 与兑换处提示；
  // 这里保留小 toast，让用户感知积分在涨。
  useToast().toast(msg, 'success')
}

/* ---------------- 任务领取 ---------------- */
function taskProgress(key) { return week.value.progress[key] || 0 }
function taskDone(key) {
  const t = WEEKLY_TASKS.find(x => x.key === key)
  return t && taskProgress(key) >= t.target
}
function taskClaimed(key) { return !!week.value.claimed[key] }
function claimTask(key) {
  const t = WEEKLY_TASKS.find(x => x.key === key)
  if (!t || !taskDone(key) || taskClaimed(key)) return
  week.value.claimed = { ...week.value.claimed, [key]: true }
  points.value += t.points
  checkBadges()
  persist()
  useToast().toast(`任务完成，+${t.points} 积分 🎉`, 'success')
}

/* ---------------- 优惠券兑换 ---------------- */
function exchange(couponId) {
  const c = COUPON_SHOP.find(x => x.id === couponId)
  if (!c) return
  if (points.value < c.cost) { useToast().toast('积分不够啦，去做任务赚积分吧～', 'error'); return }
  points.value -= c.cost
  coupons.value = { ...coupons.value, [`${c.id}-${Date.now()}`]: { ...c, at: Date.now(), code: `FOOD${Date.now() % 100000}` } }
  persist()
  useToast().toast(`兑换成功！${c.name}`, 'success')
}
const couponCount = computed(() => Object.keys(coupons.value).length)

export function useGrowth() {
  return {
    points, level, nextLevel, levelProgress,
    week, WEEKLY_TASKS, taskProgress, taskDone, taskClaimed, claimTask,
    COUPON_SHOP, exchange, coupons, couponCount,
    BADGES, unlocked, tastes,
    onAction, stats
  }
}
