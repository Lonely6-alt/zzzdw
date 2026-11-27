// 吃货成长体系：等级、每周任务、积分好礼、吃货徽章。
// 积分与兑换以 Spring Boot 后端为准；localStorage 仅作缓存与离线兜底。
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

/* ---------------- 积分好礼 ---------------- */
// 本地兜底目录；后端 /api/rewards 可用时会被数据库目录覆盖
const LOCAL_REWARDS = [
  { id: 'delivery', name: '免配送费券', cost: 40, emoji: '🛵', tag: '配送', desc: '下一单免配送费，懒人必备' },
  { id: 'c5', name: '满 30 减 5 优惠券', cost: 50, emoji: '🎟️', tag: '满减', desc: '点单立减，攒够就能兑' },
  { id: 'drink', name: '饮品升杯券', cost: 70, emoji: '🥤', tag: '饮品', desc: '奶茶咖啡免费升大杯' },
  { id: 'c12', name: '满 60 减 12 优惠券', cost: 90, emoji: '🎫', tag: '满减', desc: '聚餐更划算的万能券' },
  { id: 'dessert', name: '甜品 8 折券', cost: 120, emoji: '🍰', tag: '甜品', desc: '甜品时间专区通用' },
  { id: 'c25', name: '满 100 减 25 优惠券', cost: 150, emoji: '🧧', tag: '满减', desc: '大额满减，请客首选' },
  { id: 'blind', name: '美食盲盒', cost: 180, emoji: '🎁', tag: '惊喜', desc: '随机掉落隐藏款好礼' },
  { id: 'vip', name: '吃货月卡', cost: 200, emoji: '👑', tag: '特权', desc: '专属身份标识，月月有效' },
  { id: 'fund', name: '探店基金 20 元', cost: 260, emoji: '💰', tag: '现金', desc: '下次探店直接抵扣' },
  { id: 'merch', name: '社区定制帆布袋', cost: 300, emoji: '🛍️', tag: '周边', desc: '限量周边，背着去觅食' }
]
// 兼容旧引用
export const COUPON_SHOP = LOCAL_REWARDS

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
function readJson(key) {
  try { return JSON.parse(localStorage.getItem(key) || '{}') } catch { return {} }
}
function weekKey() {
  const d = new Date()
  const start = new Date(d.getFullYear(), 0, 1)
  const week = Math.floor((d - start) / (7 * 864e5)) + 1
  return `${d.getFullYear()}-W${week}`
}

const points = ref(readInt(PT_KEY))
const coupons = ref(readJson(COUPON_KEY))
const rewards = ref(LOCAL_REWARDS)
const unlocked = ref(readJson(BADGE_KEY))
const tastes = ref(readJson(TASTE_KEY))
const week = ref(readJson(WEEK_KEY))
if (week.value.week !== weekKey()) week.value = { week: weekKey(), progress: {}, claimed: {} }

function persist() {
  localStorage.setItem(PT_KEY, String(points.value))
  localStorage.setItem(COUPON_KEY, JSON.stringify(coupons.value))
  localStorage.setItem(BADGE_KEY, JSON.stringify(unlocked.value))
  localStorage.setItem(TASTE_KEY, JSON.stringify(tastes.value))
  localStorage.setItem(WEEK_KEY, JSON.stringify(week.value))
}

/* ---------------- 后端接口 ---------------- */
async function api(path, options = {}) {
  const token = localStorage.getItem('food_token')
  const r = await fetch(`/api${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {})
    }
  })
  if (!r.ok) {
    let msg = '请求失败'
    try { msg = (await r.json()).message || msg } catch { /* 忽略非 JSON 响应 */ }
    throw new Error(msg)
  }
  return r.json()
}

/**
 * 从后端同步积分、已兑好礼和好礼目录。
 * 未登录或后端不可用时保留 localStorage 缓存，不影响页面展示。
 */
let initPromise = null
export function initFromBackend() {
  if (!localStorage.getItem('food_token')) return Promise.resolve(false)
  if (initPromise) return initPromise
  initPromise = (async () => {
    try {
      const [me, catalog] = await Promise.all([api('/growth/me'), api('/rewards')])
      points.value = me.points
      coupons.value = (me.rewards || []).reduce((acc, r) => {
        acc[String(r.key)] = { ...r, key: r.key }
        return acc
      }, {})
      if (Array.isArray(catalog) && catalog.length) rewards.value = catalog
      persist()
      return true
    } catch {
      return false
    } finally {
      initPromise = null
    }
  })()
  return initPromise
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
const stats = ref(readJson('food_growth_stats'))
function bumpStats(k, n = 1) {
  stats.value = { ...stats.value, [k]: (stats.value[k] || 0) + n }
}

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

async function reportPoints(delta, reason) {
  try {
    const data = await api('/growth/points', {
      method: 'POST',
      body: JSON.stringify({ delta, reason })
    })
    points.value = data.points
  } catch {
    // 后端不可用时退回本地计数，保证演示不中断
    points.value += delta
  }
}

/**
 * 行为上报（点赞/收藏/评价/发笔记都从这里走）：
 * type: 'like' | 'fav' | 'comment' | 'publish'，meta: { category }
 */
async function onAction(type, meta = {}) {
  const PT = { like: 2, fav: 5, comment: 10, publish: 20 }
  const TASK_MAP = { like: 'like', fav: 'fav', comment: 'comment', publish: 'publish' }

  const gain = PT[type]
  if (gain) {
    const taskKey = TASK_MAP[type]
    await reportPoints(gain, taskKey || type)
    toastMaybe(`+${gain} 吃货积分`)
  }
  if (type === 'like') bumpStats('like')
  if (type === 'fav') bumpStats('fav')
  if (type === 'comment') bumpStats('comment')
  if (type === 'publish') bumpStats('publish')

  const taskKey = TASK_MAP[type]
  if (taskKey && meta.category) {
    if (!tastes.value[meta.category]) {
      tastes.value = { ...tastes.value, [meta.category]: Date.now() }
      const before = Object.keys(tastes.value).length
      toastMaybe(`🌈 新口味解锁：${meta.category}（已尝试 ${before} 种）`)
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
  useToast().toast(msg, 'success')
}

/* ---------------- 任务领取 ---------------- */
function taskProgress(key) { return week.value.progress[key] || 0 }
function taskDone(key) {
  const t = WEEKLY_TASKS.find(x => x.key === key)
  return t && taskProgress(key) >= t.target
}
function taskClaimed(key) { return !!week.value.claimed[key] }
async function claimTask(key) {
  const t = WEEKLY_TASKS.find(x => x.key === key)
  if (!t || !taskDone(key) || taskClaimed(key)) return
  week.value.claimed = { ...week.value.claimed, [key]: true }
  await reportPoints(t.points, `task:${key}`)
  checkBadges()
  persist()
  useToast().toast(`任务完成，+${t.points} 积分 🎉`, 'success')
}

/* ---------------- 好礼兑换 ---------------- */
async function exchange(rewardId) {
  const c = rewards.value.find(x => x.id === rewardId) || LOCAL_REWARDS.find(x => x.id === rewardId)
  if (!c) return
  if (points.value < c.cost) {
    useToast().toast('积分不够啦，去做任务赚积分吧～', 'error')
    return
  }
  try {
    const data = await api('/rewards/exchange', {
      method: 'POST',
      body: JSON.stringify({ rewardId })
    })
    points.value = data.points
    coupons.value = { ...coupons.value, [String(data.reward.key)]: { ...data.reward, key: data.reward.key } }
    persist()
    useToast().toast(`兑换成功！${data.reward.name}`, 'success')
  } catch (e) {
    useToast().toast(e.message || '兑换失败，请稍后再试', 'error')
  }
}
const couponCount = computed(() => Object.keys(coupons.value).length)

export function useGrowth() {
  return {
    points, level, nextLevel, levelProgress,
    week, WEEKLY_TASKS, taskProgress, taskDone, taskClaimed, claimTask,
    COUPON_SHOP, rewards, exchange, coupons, couponCount,
    BADGES, unlocked, tastes,
    onAction, stats, initFromBackend
  }
}
