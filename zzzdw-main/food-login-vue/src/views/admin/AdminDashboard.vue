<script setup>
// 数据仪表盘：后台统计 + 近 14 天内容趋势（手写 SVG，不引图表库）+ 店铺 Top5
import { ref, computed, onMounted } from 'vue'
import { adminFetch } from '../../composables/useAdminAuth.js'

const stats = ref(null)
const trend = ref(null)
const err = ref('')

onMounted(async () => {
  try {
    const [s, t] = await Promise.all([
      adminFetch('/api/admin/stats'),
      adminFetch('/api/admin/shop-stats')
    ])
    stats.value = s
    trend.value = t
  } catch (e) {
    err.value = e.message
  }
})

const cards = [
  { key: 'users', label: '注册用户', icon: '👥' },
  { key: 'usersActive', label: '正常状态用户', icon: '✅' },
  { key: 'posts', label: '美食笔记', icon: '📝' },
  { key: 'postsPending', label: '待审核笔记', icon: '⏳' },
  { key: 'postsApproved', label: '已通过笔记', icon: '🍚' },
  { key: 'comments', label: '评论总数', icon: '💬' },
  { key: 'categories', label: '美食分类', icon: '🍜' },
  { key: 'tags', label: '热门标签', icon: '🔥' },
  { key: 'shops', label: '店铺总数', icon: '🏠' },
  { key: 'shopsActive', label: '营业中店铺', icon: '🟢' }
]

/* ---------------- 折线图几何计算 ---------------- */
const W = 620
const H = 200
const PAD_L = 34
const PAD_R = 16
const PAD_T = 16
const PAD_B = 30

const chart = computed(() => {
  const t = trend.value
  if (!t || !t.days || !t.days.length) return null

  const n = t.days.length
  const posts = t.postsDaily || []
  const reviews = t.reviewsDaily || []
  const maxV = Math.max(1, ...posts, ...reviews)
  const innerW = W - PAD_L - PAD_R
  const innerH = H - PAD_T - PAD_B
  const baseY = PAD_T + innerH

  const x = i => PAD_L + (n === 1 ? innerW / 2 : (i * innerW) / (n - 1))
  const y = v => PAD_T + innerH * (1 - v / maxV)
  const toPts = arr => arr.map((v, i) => ({ x: x(i), y: y(v), v }))

  const postPts = toPts(posts)
  const reviewPts = toPts(reviews)
  const str = pts => pts.map(p => `${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(' ')

  return {
    labels: t.days,
    maxV,
    baseY,
    postLine: str(postPts),
    reviewLine: str(reviewPts),
    postPts,
    reviewPts,
    // 菜品折线的填充区域（视觉主色）
    areaPath: `M ${PAD_L},${baseY} L ${str(postPts).replace(/ /g, ' L ')} L ${x(n - 1).toFixed(1)},${baseY} Z`,
    grid: [0, 0.5, 1].map(r => ({ y: PAD_T + innerH * r, v: Math.round(maxV * (1 - r)) })),
    // 横轴标签抽稀，避免 14 个日期挤在一起
    tickIdx: postPts.map((_, i) => i).filter(i => i % 3 === 0 || i === n - 1)
  }
})

const topShops = computed(() => trend.value?.topShops || [])
const maxPost = computed(() => Math.max(1, ...topShops.value.map(s => s.postCount || 0)))
</script>

<template>
  <div>
    <h2>数据仪表盘</h2>
    <p v-if="err" class="err">{{ err }}</p>

    <template v-else>
      <div v-if="stats" class="grid">
        <div v-for="c in cards" :key="c.key" class="card">
          <span class="icon">{{ c.icon }}</span>
          <b>{{ stats[c.key] }}</b>
          <span class="label">{{ c.label }}</span>
        </div>
      </div>
      <p v-else class="loading">加载中…</p>

      <!-- 近 14 天趋势 -->
      <section v-if="chart" class="panel">
        <div class="p-head">
          <div>
            <h3>近 14 天内容趋势</h3>
            <p class="p-sub">按发布时间统计每日新增，最高 {{ chart.maxV }} 条/天</p>
          </div>
          <div class="legend">
            <span class="lg post"><i></i>新增菜品</span>
            <span class="lg review"><i></i>新增点评</span>
          </div>
        </div>

        <svg class="chart" :viewBox="`0 0 ${W} ${H}`" role="img" aria-label="近14天新增菜品与点评趋势">
          <g v-for="g in chart.grid" :key="'grid' + g.v">
            <line :x1="PAD_L" :x2="W - PAD_R" :y1="g.y" :y2="g.y" stroke="#f0e6db" stroke-width="1" />
            <text x="6" :y="g.y + 4" font-size="10" fill="#b3a294">{{ g.v }}</text>
          </g>

          <path :d="chart.areaPath" fill="url(#fadeFill)" />
          <defs>
            <linearGradient id="fadeFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#ff5a3c" stop-opacity=".22" />
              <stop offset="100%" stop-color="#ff5a3c" stop-opacity="0" />
            </linearGradient>
          </defs>

          <polyline :points="chart.reviewLine" fill="none" stroke="#7aa7ff" stroke-width="2"
                    stroke-linejoin="round" stroke-linecap="round" />
          <polyline :points="chart.postLine" fill="none" stroke="#ff5a3c" stroke-width="2.4"
                    stroke-linejoin="round" stroke-linecap="round" />

          <circle v-for="(p, i) in chart.reviewPts" :key="'r' + i" :cx="p.x" :cy="p.y" r="3"
                  fill="#fff" stroke="#7aa7ff" stroke-width="2">
            <title>{{ chart.labels[i] }} 点评 {{ p.v }}</title>
          </circle>
          <circle v-for="(p, i) in chart.postPts" :key="'p' + i" :cx="p.x" :cy="p.y" r="3.4"
                  fill="#fff" stroke="#ff5a3c" stroke-width="2.4">
            <title>{{ chart.labels[i] }} 菜品 {{ p.v }}</title>
          </circle>

          <text v-for="i in chart.tickIdx" :key="'x' + i" :x="chart.postPts[i].x" :y="H - 8"
                font-size="10" fill="#b3a294" text-anchor="middle">{{ chart.labels[i] }}</text>
        </svg>
      </section>

      <!-- 店铺 Top5 -->
      <section v-if="topShops.length" class="panel">
        <div class="p-head">
          <div>
            <h3>菜品最多的店铺 Top5</h3>
            <p class="p-sub">按在售菜品数排序，同数量看平均评分</p>
          </div>
        </div>
        <div class="bars">
          <div v-for="(s, i) in topShops" :key="s.shopId" class="bar-row">
            <span class="rank">{{ i + 1 }}</span>
            <span class="b-emoji">{{ s.emoji || '🏠' }}</span>
            <span class="b-name">
              {{ s.shopName }}<em>@{{ s.ownerName || '—' }}</em>
            </span>
            <div class="b-track">
              <div class="b-fill" :style="{ width: ((s.postCount || 0) / maxPost * 100) + '%' }"></div>
            </div>
            <span class="b-val">{{ s.postCount || 0 }} 道</span>
            <span class="b-rate">★ {{ Number(s.avgRating || 0).toFixed(1) }}</span>
          </div>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
h2{ margin: 0 0 18px; color: #3a2f2a; }
.grid{ display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 14px; }
.card{
  background: #fff; border-radius: 16px; padding: 18px; display: flex; flex-direction: column; gap: 4px;
  box-shadow: 0 4px 16px rgba(60,40,20,.06);
}
.icon{ font-size: 22px; }
.card b{ font-size: 26px; color: #ff5a3c; }
.label{ font-size: 13px; color: #999; }
.err{ color: #e5484d; }
.loading{ color: #999; }

/* 面板 */
.panel{ margin-top: 22px; background: #fff; border-radius: 18px; padding: 20px 22px;
  box-shadow: 0 4px 16px rgba(60,40,20,.06); }
.p-head{ display: flex; align-items: flex-start; justify-content: space-between; gap: 14px; flex-wrap: wrap; margin-bottom: 12px; }
.p-head h3{ font-size: 15.5px; color: #3a2f2a; }
.p-sub{ margin-top: 4px; font-size: 12px; color: #a49789; }
.legend{ display: flex; gap: 16px; }
.lg{ display: inline-flex; align-items: center; gap: 6px; font-size: 12px; color: #7a6a5d; font-weight: 600; }
.lg i{ width: 16px; height: 3px; border-radius: 2px; display: inline-block; }
.lg.post i{ background: #ff5a3c; }
.lg.review i{ background: #7aa7ff; }

.chart{ width: 100%; height: auto; display: block; margin-top: 4px; }

/* Top5 横条 */
.bars{ display: flex; flex-direction: column; gap: 12px; }
.bar-row{ display: grid; grid-template-columns: 18px 24px 1.4fr 2fr 62px 54px;
  align-items: center; gap: 10px; font-size: 13px; }
.rank{ font-weight: 800; color: #c8771a; text-align: center; font-size: 12px; }
.b-emoji{ font-size: 18px; }
.b-name{ color: #3a2f2a; font-weight: 700; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.b-name em{ font-style: normal; font-weight: 500; color: #a49789; font-size: 11.5px; margin-left: 6px; }
.b-track{ height: 9px; background: #f6efe6; border-radius: 999px; overflow: hidden; }
.b-fill{ height: 100%; border-radius: 999px; background: linear-gradient(90deg, #ff9a5c, #ff5a3c);
  min-width: 3px; transition: width .5s ease; }
.b-val{ text-align: right; font-weight: 700; color: #3a2f2a; }
.b-rate{ text-align: right; color: #c8771a; font-weight: 700; font-size: 12.5px; }

@media (max-width: 640px){
  .bar-row{ grid-template-columns: 16px 20px 1fr 60px; }
  .b-track, .b-rate{ display: none; }
}
</style>
