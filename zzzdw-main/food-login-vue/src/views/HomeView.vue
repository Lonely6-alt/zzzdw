<script setup>
import { ref, onMounted, onUnmounted, computed, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { authUser, getToken } from '../composables/useAuth.js'
import { useReviews } from '../composables/useReviews.js'
import { useLikes } from '../composables/useLikes.js'
import { useToast } from '../composables/useToast.js'
import { CAT_NAMES, catIcon } from '../data/categories.js'
import PostCard from '../components/PostCard.vue'
import HScroller from '../components/HScroller.vue'
import { useFoodMeta } from '../composables/useFoodMeta.js'
import { useGrowth } from '../composables/useGrowth.js'

const router = useRouter()
const { toast } = useToast()
const { displayRating } = useReviews()
const { countOf, seed } = useLikes()
const { noteTypeOf, setNoteType } = useFoodMeta()
const growth = useGrowth()

/* ---------------- 状态 ---------------- */
const posts = ref([])
const loading = ref(true)
const failed = ref(false)
const keyword = ref('')
const sortBy = ref('default') // default | hot | rating
const activeTab = ref('hot')  // hot | explore | rank | new

const PAGE_SIZE = 12
const page = ref(1)           // 当前页码（分页浏览，上一页/下一页切换）

const TABS = [
  { key: 'hot', label: '热门', emoji: '🔥' },
  { key: 'explore', label: '探店', emoji: '🧭' },
  { key: 'rank', label: '排行榜', emoji: '🏆' },
  { key: 'new', label: '新品', emoji: '✨' }
]

const SORTS = [
  { key: 'default', label: '综合推荐', desc: '按当前标签的默认顺序' },
  { key: 'hot', label: '人气优先', desc: '点赞、收藏、点评综合热度' },
  { key: 'rating', label: '评分优先', desc: '评分从高到低' }
]

/* ---------------- 展示辅助 ---------------- */
const SHOP_POOL = ['巷口小馆', '老地方食堂', '街角食光', '私房一味', '深夜食堂', '暖食屋', '半日闲', '食光小铺', '鲜物记', '好味来', '慢炖锅', '一味居']
function shopName(p) {
  return p.shopName || SHOP_POOL[(Number(p.id) || 1) % SHOP_POOL.length]
}
function likesOf(p) {
  return countOf(p.id, p.likeCount || 0)
}
function ratingOf(p) {
  return displayRating(p) || 0
}

/* ---------------- 筛选 / 排序 ---------------- */
function heat(p) {
  return likesOf(p) * 3 + (Number(p.favoriteCount) || 0) * 2 + (Number(p.reviewCount) || 0) * 5
}

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  const list = posts.value.filter(p => {
    if (!kw) return true
    return (p.title || '').toLowerCase().includes(kw)
      || (p.content || '').toLowerCase().includes(kw)
      || (p.shopName || '').toLowerCase().includes(kw)
      || (p.author || '').toLowerCase().includes(kw)
      || (p.category || '').toLowerCase().includes(kw)
  })

  const arr = [...list]
  if (sortBy.value === 'hot') {
    arr.sort((a, b) => likesOf(b) - likesOf(a) || b.id - a.id)
  } else if (sortBy.value === 'rating') {
    arr.sort((a, b) => ratingOf(b) - ratingOf(a) || (b.reviewCount || 0) - (a.reviewCount || 0))
  } else if (activeTab.value === 'explore') {
    arr.sort((a, b) => (b.reviewCount || 0) - (a.reviewCount || 0) || heat(b) - heat(a))
  } else if (activeTab.value === 'rank') {
    arr.sort((a, b) => ratingOf(b) - ratingOf(a) || (b.reviewCount || 0) - (a.reviewCount || 0))
  } else if (activeTab.value === 'new') {
    arr.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0) || b.id - a.id)
  } else {
    arr.sort((a, b) => heat(b) - heat(a))
  }
  return arr
})

const totalPages = computed(() => Math.max(1, Math.ceil(filtered.value.length / PAGE_SIZE)))
const visible = computed(() => filtered.value.slice((page.value - 1) * PAGE_SIZE, page.value * PAGE_SIZE))

// 页码列表：页数多时中间用省略号折叠，始终能看到首尾页
const pageList = computed(() => {
  const total = totalPages.value
  const cur = page.value
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1)
  const set = new Set([1, 2, total - 1, total, cur, cur - 1, cur + 1])
  const arr = [...set].filter(n => n >= 1 && n <= total).sort((a, b) => a - b)
  const out = []
  arr.forEach((n, i) => {
    if (i && n - arr[i - 1] > 1) out.push('…')
    out.push(n)
  })
  return out
})

function gotoPage(n) {
  if (n === '…' || n === page.value || n < 1 || n > totalPages.value) return
  page.value = n
  nextTick(() => {
    const el = document.querySelector('.grid')
    if (el) window.scrollTo({ top: el.offsetTop - 70, behavior: 'smooth' })
  })
}

watch([keyword, activeTab, sortBy], () => { page.value = 1 })

/* ---------------- 避雷板块 ---------------- */
const avoidPosts = computed(() => {
  return posts.value
    .filter(p => noteTypeOf(p) === 'avoid')
    .sort((a, b) => ratingOf(a) - ratingOf(b) || (b.reviewCount || 0) - (a.reviewCount || 0))
    .slice(0, 8)
})

/* ---------------- 季节限定专区（随月份自动换主题） ---------------- */
const SEASONS = {
  spring: { name: '春日尝鲜季', emoji: '🌸', months: [3, 4, 5], cats: ['轻食沙拉', '甜品时间', '咖啡馆'],
    desc: '野餐轻食、第一口春日甜品与花香咖啡，把春天吃进肚子里', grad: 'linear-gradient(120deg,#9be15d,#00e3ae)' },
  summer: { name: '夏日冰爽季', emoji: '🍉', months: [6, 7, 8], cats: ['甜品时间', '咖啡馆', '烧烤夜宵'],
    desc: '冰饮、雪糕与晚风烧烤，清凉一夏的正确打开方式', grad: 'linear-gradient(120deg,#f6d365,#fda085)' },
  autumn: { name: '秋日暖心季', emoji: '🍂', months: [9, 10, 11], cats: ['面食控', '火锅江湖', '烧烤夜宵'],
    desc: '一碗热汤面、一顿围炉火锅，贴好秋膘再过冬', grad: 'linear-gradient(120deg,#ff9a44,#fc6076)' },
  winter: { name: '冬日进补季', emoji: '♨️', months: [12, 1, 2], cats: ['火锅江湖', '面食控', '日料局'],
    desc: '沸腾的锅子与滚烫的汤头，寒风里的治愈系美味', grad: 'linear-gradient(120deg,#4facfe,#c471ed)' }
}
const season = computed(() => {
  const m = new Date().getMonth() + 1
  for (const s of Object.values(SEASONS)) if (s.months.includes(m)) return s
  return SEASONS.autumn
})
const seasonPosts = computed(() => {
  return posts.value
    .filter(p => season.value.cats.includes(p.category))
    .sort((a, b) => ratingOf(b) - ratingOf(a))
    .slice(0, 6)
})

const sortLabel = computed(() => {
  if (sortBy.value === 'hot') return '人气'
  if (sortBy.value === 'rating') return '评分'
  return '筛选'
})

/* ---------------- 加载 ---------------- */
function authHeaders() {
  const t = getToken()
  return t ? { Authorization: `Bearer ${t}` } : {}
}

async function loadPosts() {
  loading.value = true
  failed.value = false
  try {
    const r = await fetch('/api/posts', { headers: authHeaders() })
    if (!r.ok) throw new Error(`HTTP ${r.status}`)
    const data = await r.json()
    posts.value = Array.isArray(data) ? data : []
    seed(posts.value)
  } catch {
    failed.value = true
    posts.value = []
  } finally {
    loading.value = false
    page.value = 1
  }
}

/* ---------------- 下拉刷新（触屏）+ 滚动加载 ---------------- */
const pullDist = ref(0)
const refreshing = ref(false)
let touchStartY = 0
let pulling = false

function onTouchStart(e) {
  if (window.scrollY > 0 || refreshing.value) return
  touchStartY = e.touches[0].clientY
  pulling = true
}
function onTouchMove(e) {
  if (!pulling) return
  const dy = e.touches[0].clientY - touchStartY
  if (dy <= 0) { pullDist.value = 0; return }
  pullDist.value = Math.min(72, dy * 0.5)
}
async function onTouchEnd() {
  if (!pulling) return
  pulling = false
  const trigger = pullDist.value > 48
  pullDist.value = 0
  if (trigger) await refresh()
}
async function refresh() {
  if (refreshing.value) return
  refreshing.value = true
  await loadPosts()
  refreshing.value = false
  toast('已刷新', 'success')
}

onMounted(async () => {
  window.addEventListener('touchstart', onTouchStart, { passive: true })
  window.addEventListener('touchmove', onTouchMove, { passive: true })
  window.addEventListener('touchend', onTouchEnd)
  await loadPosts()
})

onUnmounted(() => {
  window.removeEventListener('touchstart', onTouchStart)
  window.removeEventListener('touchmove', onTouchMove)
  window.removeEventListener('touchend', onTouchEnd)
})

/* ---------------- 交互 ---------------- */
function openPost(id) { router.push(`/post/${id}`) }

const showFilter = ref(false)
function pickSort(key) {
  sortBy.value = key
  showFilter.value = false
  nextTick(() => window.scrollTo({ top: 0, behavior: 'smooth' }))
}
function resetAll() {
  keyword.value = ''
  sortBy.value = 'default'
  activeTab.value = 'hot'
  page.value = 1
}

/* ---------------- 发布 ---------------- */
const showForm = ref(false)
const form = ref({ title: '', category: '面食控', content: '', emoji: '🍜', noteType: 'plant' })
const formMsg = ref('')
const EMOJI_PICKS = ['🍜', '🍣', '🍔', '🥗', '🍰', '☕', '🍢', '🍲', '🍱', '🥟', '🍡', '🍟']
const NOTE_TYPES = [
  { key: 'plant', label: '种草', emoji: '🌱', desc: '真心推荐，让大家去尝尝' },
  { key: 'avoid', label: '避雷', emoji: '⚠️', desc: '踩雷警告，帮大家避坑' }
]
async function publish() {
  formMsg.value = ''
  if (!form.value.title.trim()) { formMsg.value = '先给这道美食起个名字吧～'; return }
  if (!form.value.content.trim()) { formMsg.value = '再写两句味道和心得吧～'; return }
  try {
    const r = await fetch('/api/posts', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...authHeaders() },
      body: JSON.stringify(form.value)
    })
    const data = await r.json().catch(() => ({}))
    if (!r.ok) { formMsg.value = data.message || '发布失败'; return }
    // 记录笔记类型（种草/避雷），并计入成长体系（发布笔记 +20 积分、口味挑战）
    setNoteType({ title: form.value.title.trim() }, form.value.noteType)
    growth.onAction('publish', { category: form.value.category })
    showForm.value = false
    form.value = { title: '', category: '面食控', content: '', emoji: '🍜', noteType: 'plant' }
    await loadPosts()
    toast('发布成功 🎉', 'success')
  } catch { formMsg.value = '网络错误' }
}
</script>

<template>
  <div class="home">
    <!-- 顶部：搜索框 + 筛选按钮 -->
    <header class="head">
      <div class="head-top">
        <div>
          <h1>发现好味道</h1>
          <p class="sub" v-if="authUser">Hi，{{ authUser }} 👋 今天想吃点什么？</p>
          <p class="sub" v-else>记录 · 分享 · 收藏你的私藏美食地图</p>
        </div>
        <button class="icon-btn" type="button" title="刷新" :disabled="refreshing" @click="refresh">
          <span :class="{ spin: refreshing }">↻</span>
        </button>
      </div>

      <div class="search-row">
        <div class="searchbar">
          <span class="ic">🔍</span>
          <input v-model="keyword" type="search" placeholder="搜店名、菜品、探店笔记…" />
          <button v-if="keyword" class="clear" type="button" aria-label="清空" @click="keyword = ''">✕</button>
        </div>
        <button class="filter-btn" :class="{ on: sortBy !== 'default' }" type="button" @click="showFilter = true">
          <span class="fi">⚙</span>{{ sortLabel }}
        </button>
      </div>
    </header>

    <!-- 横向可滑分类标签 -->
    <nav class="tabs" aria-label="内容标签">
      <button
        v-for="t in TABS"
        :key="t.key"
        type="button"
        class="tab"
        :class="{ on: activeTab === t.key }"
        @click="activeTab = t.key"
      >{{ t.emoji }} {{ t.label }}</button>
    </nav>


    <!-- 避雷预警板块：单独展示避雷笔记，帮大家避坑 -->
    <section v-if="!keyword.trim() && avoidPosts.length" class="avoid-sec" aria-label="避雷笔记">
      <div class="sec-title">
        <h2>⚠️ 避雷预警</h2>
        <span class="sec-desc">真实踩雷反馈，下单前先看一眼</span>
      </div>
      <HScroller>
        <article
          v-for="(p, i) in avoidPosts"
          :key="'av' + p.id"
          class="avoid-card"
          :style="{ '--i': i }"
          @click="openPost(p.id)"
        >
          <div class="av-top">
            <span class="av-emoji">{{ p.emoji || '⚠️' }}</span>
            <span class="av-score" :class="{ bad: ratingOf(p) > 0 && ratingOf(p) < 3.5 }">
              ★ {{ ratingOf(p).toFixed(1) }}
            </span>
          </div>
          <h4 class="av-title">{{ p.title }}</h4>
          <p class="av-shop">🏠 {{ shopName(p) }} · {{ p.category }}</p>
          <p class="av-reason">{{ (p.content || '').slice(0, 42) }}{{ (p.content || '').length > 42 ? '…' : '' }}</p>
        </article>
      </HScroller>
    </section>

    <!-- 季节限定专区：随季节自动更换主题 -->
    <section v-if="!keyword.trim() && seasonPosts.length" class="season-sec" :style="{ '--sg': season.grad }" aria-label="季节限定">
      <div class="season-head">
        <span class="season-emoji">{{ season.emoji }}</span>
        <div class="season-text">
          <h2>{{ season.name }} <em class="season-tag">季节限定</em></h2>
          <p>{{ season.desc }}</p>
        </div>
      </div>
      <HScroller>
        <article
          v-for="(p, i) in seasonPosts"
          :key="'se' + p.id"
          class="season-card"
          :style="{ '--i': i }"
          @click="openPost(p.id)"
        >
          <div class="se-cover">
            <span class="se-emoji">{{ p.emoji || catIcon(p.category) }}</span>
            <span class="se-cat">{{ catIcon(p.category) }} {{ p.category }}</span>
          </div>
          <div class="se-body">
            <h4>{{ p.title }}</h4>
            <span class="se-score">★ {{ ratingOf(p).toFixed(1) }} · 💬 {{ p.reviewCount || 0 }}</span>
          </div>
        </article>
      </HScroller>
    </section>

    <!-- 下拉刷新提示（触屏） -->
    <div v-if="pullDist > 0" class="pull-tip" :style="{ height: pullDist + 'px' }">
      {{ pullDist > 48 ? '松开刷新' : '下拉刷新' }}
    </div>

    <!-- 加载中 -->
    <div v-if="loading" class="grid">
      <div v-for="n in 6" :key="'sk' + n" class="sk-card">
        <div class="sk-cover"></div>
        <div class="sk-body">
          <div class="sk-line w70"></div>
          <div class="sk-line w50"></div>
        </div>
      </div>
    </div>

    <!-- 加载失败 -->
    <div v-else-if="failed" class="state">
      <div class="state-emoji">😵</div>
      <p class="state-title">加载失败了</p>
      <p class="state-sub">检查一下网络，或者稍后再试</p>
      <button class="state-btn" type="button" @click="loadPosts">重新加载</button>
    </div>

    <!-- 无结果 -->
    <div v-else-if="!filtered.length" class="state">
      <div class="state-emoji">🍽️</div>
      <p class="state-title">{{ keyword.trim() ? '没有找到相关笔记' : '这个标签下还没有笔记' }}</p>
      <p class="state-sub">换个标签或关键词试试～</p>
      <button class="state-btn" type="button" @click="resetAll">重置筛选</button>
    </div>

    <!-- 卡片流：多图轮播卡片 + 悬浮浮窗 -->
    <div v-else class="grid">
      <PostCard
        v-for="(p, i) in visible"
        :key="p.id"
        :p="p"
        :style="{ '--i': i }"
        @open="openPost"
      />
    </div>

    <!-- 分页：上一页 / 页码 / 下一页 -->
    <nav v-if="!loading && !failed && totalPages > 1" class="pager" aria-label="分页">
      <button
        type="button"
        class="pg-btn"
        :disabled="page === 1"
        @click="gotoPage(page - 1)"
      >‹ 上一页</button>
      <template v-for="(n, i) in pageList" :key="i">
        <span v-if="n === '…'" class="pg-dots">…</span>
        <button
          v-else
          type="button"
          class="pg-num"
          :class="{ on: n === page }"
          @click="gotoPage(n)"
        >{{ n }}</button>
      </template>
      <button
        type="button"
        class="pg-btn"
        :disabled="page === totalPages"
        @click="gotoPage(page + 1)"
      >下一页 ›</button>
    </nav>
    <p v-else-if="!loading && !failed && filtered.length" class="pg-only">— 共 {{ filtered.length }} 篇笔记 —</p>

    <!-- 发布入口 -->
    <button class="fab" type="button" title="发布美食笔记" @click="showForm = true">＋</button>

    <!-- 筛选面板 -->
    <div v-if="showFilter" class="mask" @click.self="showFilter = false">
      <div class="sheet">
        <div class="handle"></div>
        <h3>排序方式</h3>
        <button
          v-for="s in SORTS"
          :key="s.key"
          type="button"
          class="sort-opt"
          :class="{ on: sortBy === s.key }"
          @click="pickSort(s.key)"
        >
          <span class="so-text">
            <b>{{ s.label }}</b>
            <i>{{ s.desc }}</i>
          </span>
          <span class="so-radio">{{ sortBy === s.key ? '●' : '○' }}</span>
        </button>
        <button class="sheet-done" type="button" @click="showFilter = false">完成</button>
      </div>
    </div>

    <!-- 发布弹窗 -->
    <div v-if="showForm" class="mask" @click.self="showForm = false">
      <div class="sheet form-sheet">
        <h3>发布一道美食</h3>
        <p class="sheet-sub">分享你的私藏，让更多人尝到好味道</p>
        <div class="field">
          <label>笔记类型</label>
          <div class="type-picker">
            <button
              v-for="t in NOTE_TYPES"
              :key="t.key"
              type="button"
              class="type-opt"
              :class="{ on: form.noteType === t.key, avoid: t.key === 'avoid' }"
              @click="form.noteType = t.key"
            >
              <b>{{ t.emoji }} {{ t.label }}</b>
              <i>{{ t.desc }}</i>
            </button>
          </div>
        </div>
        <div class="field">
          <label>标题</label>
          <input v-model="form.title" maxlength="30" placeholder="例如：巷子里的无名拉面" />
        </div>
        <div class="field">
          <label>归入分类</label>
          <div class="cat-picker">
            <button
              v-for="c in CAT_NAMES"
              :key="c"
              type="button"
              class="cat-opt"
              :class="{ on: form.category === c }"
              @click="form.category = c"
            >{{ catIcon(c) }} {{ c }}</button>
          </div>
        </div>
        <div class="field">
          <label>选个图标</label>
          <div class="emoji-picker">
            <button
              v-for="e in EMOJI_PICKS"
              :key="e"
              type="button"
              class="emoji-opt"
              :class="{ on: form.emoji === e }"
              @click="form.emoji = e"
            >{{ e }}</button>
          </div>
        </div>
        <div class="field">
          <label>内容</label>
          <textarea v-model="form.content" rows="4" maxlength="200" placeholder="分享一下味道、位置和心得…"></textarea>
        </div>
        <div class="msg">{{ formMsg }}</div>
        <div class="actions">
          <button class="ghost" type="button" @click="showForm = false">取消</button>
          <button class="btn" type="button" @click="publish">发布</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.home{ position:relative; max-width:1100px; margin:0 auto; padding:20px 22px 110px; }

/* ===== 顶部 ===== */
.head{ margin-bottom:14px; }
.head-top{ display:flex; align-items:flex-start; justify-content:space-between; gap:12px; }
.head h1{ font-size:24px; font-weight:800; letter-spacing:.4px; }
.sub{ font-size:13px; color:var(--muted); margin-top:4px; }
.icon-btn{ flex-shrink:0; width:38px; height:38px; border-radius:50%; cursor:pointer; font-size:17px; color:var(--tomato);
  border:1.5px solid #f0e2d4; background:#fff; transition:.2s; }
.icon-btn:hover{ border-color:var(--orange); transform:translateY(-1px); }
.icon-btn .spin{ display:inline-block; animation:spin .8s linear infinite; }
@keyframes spin{ to{ transform:rotate(360deg); } }

.search-row{ display:flex; gap:10px; margin-top:13px; }
.searchbar{ flex:1; min-width:0; display:flex; align-items:center; gap:9px; height:44px; padding:0 14px;
  background:#fff; border:1.5px solid #f0e2d4; border-radius:999px; box-shadow:0 6px 16px rgba(255,120,80,.07); transition:.2s; }
.searchbar:focus-within{ border-color:var(--orange); box-shadow:0 8px 20px rgba(255,90,60,.14); }
.searchbar .ic{ font-size:15px; opacity:.55; }
.searchbar input{ flex:1; min-width:0; border:0; outline:none; background:transparent; font-size:14.5px; color:var(--ink); font-family:inherit; }
.searchbar .clear{ flex-shrink:0; width:24px; height:24px; border:0; border-radius:50%; cursor:pointer;
  background:#f2eae1; color:var(--muted); font-size:11px; line-height:1; }
.searchbar .clear:hover{ background:#e9ded3; }

.filter-btn{ flex-shrink:0; display:flex; align-items:center; gap:5px; height:44px; padding:0 16px; cursor:pointer;
  border:1.5px solid #ffd9bf; background:#fff3e9; color:var(--tomato); font-size:13.5px; font-weight:800;
  border-radius:999px; font-family:inherit; transition:.2s; }
.filter-btn:hover{ background:#ffe9d8; }
.filter-btn.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); color:#fff; border-color:transparent;
  box-shadow:0 6px 14px rgba(255,90,60,.26); }
.filter-btn .fi{ font-size:12px; }

/* ===== 标签 ===== */
.tabs{ display:flex; gap:8px; overflow-x:auto; padding:2px 2px 4px; margin:14px 0 12px; scrollbar-width:none; }
.tabs::-webkit-scrollbar{ display:none; }
.tab{ flex-shrink:0; border:1.5px solid #ecdfd2; background:#fff; color:var(--muted); font-size:13px; font-weight:700;
  padding:8px 16px; border-radius:999px; cursor:pointer; font-family:inherit; transition:.2s; white-space:nowrap; }
.tab:hover{ border-color:var(--orange); color:var(--tomato); }
.tab.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); color:#fff; border-color:transparent;
  box-shadow:0 6px 14px rgba(255,90,60,.26); }

/* 下拉刷新 */
.pull-tip{ display:flex; align-items:center; justify-content:center; font-size:12px; color:var(--muted); overflow:hidden; transition:height .1s; }

/* ===== 横滑板块通用（翻页按钮在 HScroller 组件内） ===== */
.sec-title{ display:flex; align-items:baseline; gap:10px; margin:4px 0 10px; }
.sec-title h2{ font-size:17px; font-weight:800; margin:0; }
.sec-desc{ font-size:12px; color:var(--muted); }

/* ===== 避雷板块 ===== */
.avoid-sec{ margin:6px 0 18px; }
.avoid-card{ flex:0 0 240px; background:#fff; border:1.5px solid #ffd9d0; border-radius:16px; padding:13px 14px;
  cursor:pointer; transition:.2s; animation:cardIn .4s backwards; animation-delay:calc(var(--i,0) * 40ms);
  box-shadow:0 8px 18px rgba(220,80,50,.08); }
.avoid-card:hover{ transform:translateY(-4px); box-shadow:0 14px 26px rgba(220,80,50,.16); border-color:#ff9d85; }
.av-top{ display:flex; align-items:center; justify-content:space-between; }
.av-emoji{ font-size:26px; }
.av-score{ font-size:12.5px; font-weight:800; color:#b07010; }
.av-score.bad{ color:#c23b22; }
.av-title{ margin:8px 0 4px; font-size:13.5px; font-weight:800; color:var(--ink);
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.av-shop{ margin:0; font-size:11.5px; color:var(--muted); }
.av-reason{ margin:7px 0 0; font-size:11.5px; color:#8a7663; line-height:1.5;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }

/* ===== 季节限定专区 ===== */
.season-sec{ position:relative; overflow:hidden; border-radius:22px; padding:18px 18px 8px; margin:6px 0 18px;
  background:var(--sg); box-shadow:0 14px 30px rgba(120,60,20,.16); color:#fff; }
.season-sec::before{ content:""; position:absolute; inset:0; background:radial-gradient(circle at 88% 12%,rgba(255,255,255,.28),transparent 42%); pointer-events:none; }
.season-head{ position:relative; display:flex; align-items:center; gap:14px; margin-bottom:12px; }
.season-emoji{ font-size:40px; filter:drop-shadow(0 6px 10px rgba(80,40,10,.3)); }
.season-text h2{ margin:0; font-size:18px; font-weight:800; display:flex; align-items:center; gap:8px; }
.season-tag{ font-style:normal; font-size:10.5px; font-weight:800; padding:3px 9px; border-radius:999px;
  background:rgba(255,255,255,.9); color:#c2502a; letter-spacing:1px; }
.season-text p{ margin:5px 0 0; font-size:12.5px; opacity:.94; }
.season-card{ position:relative; flex:0 0 190px; background:rgba(255,255,255,.94); border-radius:16px; overflow:hidden;
  cursor:pointer; transition:.2s; animation:cardIn .4s backwards; animation-delay:calc(var(--i,0) * 40ms); color:var(--ink); }
.season-card:hover{ transform:translateY(-4px); box-shadow:0 14px 26px rgba(60,30,10,.22); }
.se-cover{ position:relative; height:96px; display:flex; align-items:center; justify-content:center; background:#fff3e6; }
.se-emoji{ font-size:44px; transition:transform .3s; }
.season-card:hover .se-emoji{ transform:scale(1.15) rotate(-6deg); }
.se-cat{ position:absolute; left:9px; bottom:8px; font-size:10.5px; font-weight:700; color:#fff;
  padding:2px 8px; border-radius:999px; background:rgba(40,20,10,.34); backdrop-filter:blur(3px); }
.se-body{ padding:10px 12px 12px; }
.se-body h4{ margin:0; font-size:12.5px; font-weight:800; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.se-score{ font-size:11px; color:var(--muted); display:block; margin-top:4px; }

/* ===== 发布：笔记类型选择 ===== */
.type-picker{ display:flex; gap:9px; }
.type-opt{ flex:1; text-align:left; border:1.5px solid #ecdfd2; background:#fff; border-radius:13px;
  padding:10px 13px; cursor:pointer; font-family:inherit; transition:.2s; }
.type-opt b{ display:block; font-size:13.5px; color:var(--ink); }
.type-opt i{ font-style:normal; font-size:11px; color:var(--muted); display:block; margin-top:3px; }
.type-opt.on{ border-color:var(--orange); background:#fff4ea; }
.type-opt.on b{ color:var(--tomato); }
.type-opt.avoid.on{ border-color:#ff9d85; background:#fff1ed; }
.type-opt.avoid.on b{ color:#c23b22; }

/* ===== 卡片流 ===== */
.grid{ display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
@keyframes cardIn{ from{ opacity:0; transform:translateY(10px); } to{ opacity:1; transform:translateY(0); } }

/* 分页 */
.pager{ display:flex; justify-content:center; align-items:center; gap:7px; padding:24px 0 6px; flex-wrap:wrap; }
.pg-btn{ border:1.5px solid #f0ddd0; background:#fff; color:#8a6a52; font-size:12.5px; font-weight:700;
  padding:7px 14px; border-radius:999px; cursor:pointer; font-family:inherit; transition:.2s; }
.pg-btn:hover:not(:disabled){ border-color:var(--orange); color:var(--tomato); }
.pg-btn:disabled{ opacity:.4; cursor:not-allowed; }
.pg-num{ min-width:32px; height:32px; border:0; border-radius:50%; background:transparent; color:#8a6a52;
  font-size:13px; font-weight:700; cursor:pointer; font-family:inherit; transition:.2s; }
.pg-num:hover{ background:#ffefe4; color:var(--tomato); }
.pg-num.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); color:#fff;
  box-shadow:0 5px 12px rgba(255,90,60,.3); }
.pg-dots{ color:#c4ab94; font-weight:700; padding:0 2px; }
.pg-only{ text-align:center; padding:24px 0 6px; font-size:12.5px; color:#c4ab94; }
.spinner{ width:26px; height:26px; border-radius:50%; border:3px solid #f0e6db; border-top-color:var(--tomato); animation:spin .8s linear infinite; }

/* 骨架屏 */
.sk-card{ background:#fff; border:1.5px solid #f6ebe0; border-radius:18px; overflow:hidden; }
.sk-cover{ width:100%; aspect-ratio:4 / 3; background:#f6eee6; }
.sk-body{ padding:12px 13px 14px; }
.sk-line{ height:11px; border-radius:6px; background:#f4ece4; animation:shimmer 1.4s ease-in-out infinite; }
.sk-line + .sk-line{ margin-top:9px; }
.sk-line.w70{ width:70%; } .sk-line.w50{ width:50%; }
@keyframes shimmer{ 0%,100%{ opacity:1; } 50%{ opacity:.45; } }

/* 空 / 错误状态 */
.state{ text-align:center; padding:56px 20px 30px; }
.state-emoji{ font-size:44px; opacity:.6; }
.state-title{ font-size:15px; font-weight:800; color:var(--ink); margin-top:12px; }
.state-sub{ font-size:12.5px; color:var(--muted); margin-top:6px; }
.state-btn{ margin-top:16px; border:0; border-radius:999px; padding:10px 22px; font-size:13px; font-weight:800; color:#fff;
  cursor:pointer; background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 8px 18px rgba(255,90,60,.28); }

:deep(.hl){ background:linear-gradient(120deg,#ffe08a,#ffd166); color:#5a3b00; border-radius:4px; padding:0 2px; font-weight:700; }

/* 发布按钮 */
.fab{ position:fixed; right:24px; bottom:24px; z-index:15; width:56px; height:56px; border:0; border-radius:50%; cursor:pointer;
  font-size:25px; color:#fff; line-height:1; background:linear-gradient(120deg,var(--orange),var(--tomato));
  box-shadow:0 12px 26px rgba(255,90,60,.4); transition:.2s; }
.fab:hover{ transform:translateY(-3px) scale(1.05); }

/* 弹层 */
.mask{ position:fixed; inset:0; background:rgba(40,20,10,.42); display:flex; align-items:flex-end; justify-content:center; z-index:20; animation:mfade .18s ease; }
@keyframes mfade{ from{ opacity:0; } to{ opacity:1; } }
.sheet{ width:min(520px,100%); background:#fff; border-radius:22px 22px 0 0; padding:10px 22px 22px; animation:mpop .24s cubic-bezier(.2,.9,.3,1.15); }
@keyframes mpop{ from{ transform:translateY(20px); opacity:.6; } to{ transform:translateY(0); opacity:1; } }
.handle{ width:36px; height:4px; border-radius:2px; background:#eadfd3; margin:2px auto 12px; }
.sheet h3{ font-size:15px; font-weight:800; margin-bottom:10px; }
.sort-opt{ display:flex; align-items:center; gap:10px; width:100%; text-align:left; cursor:pointer;
  border:1.5px solid #f2e7db; background:#fffdfb; border-radius:13px; padding:12px 14px; margin-bottom:8px; font-family:inherit; transition:.2s; }
.sort-opt:hover{ border-color:#ffd9bf; }
.sort-opt.on{ border-color:var(--orange); background:#fff4ea; }
.so-text{ display:flex; flex-direction:column; gap:3px; flex:1; min-width:0; }
.so-text b{ font-size:13.5px; color:var(--ink); }
.sort-opt.on .so-text b{ color:var(--tomato); }
.so-text i{ font-style:normal; font-size:11.5px; color:var(--muted); }
.so-radio{ color:#d8c8b8; font-size:14px; }
.sort-opt.on .so-radio{ color:var(--orange); }
.sheet-done{ width:100%; margin-top:8px; border:0; border-radius:999px; padding:12px; font-size:14px; font-weight:800; color:#fff;
  cursor:pointer; background:linear-gradient(120deg,var(--orange),var(--tomato)); font-family:inherit; }

/* 发布弹窗 */
.form-sheet{ border-radius:20px; width:min(460px,100%); max-height:88vh; overflow:auto; }
.mask:has(.form-sheet){ align-items:center; padding:20px; }
.sheet-sub{ font-size:12.5px; color:var(--muted); margin-bottom:14px; }
.field{ margin-bottom:13px; }
.field label{ display:block; font-size:12.5px; color:var(--muted); margin-bottom:6px; font-weight:700; }
.field input, .field textarea{ width:100%; padding:11px 13px; border:1.5px solid #ecdfd2; border-radius:11px; font-size:14px;
  outline:none; font-family:inherit; resize:vertical; color:var(--ink); }
.field input:focus, .field textarea:focus{ border-color:var(--orange); }
.cat-picker{ display:flex; flex-wrap:wrap; gap:8px; }
.cat-opt{ border:1.5px solid #ecdfd2; background:#fff; color:#7a6a5d; font-family:inherit; padding:7px 12px;
  border-radius:12px; font-size:12.5px; font-weight:700; cursor:pointer; transition:.2s; }
.cat-opt:hover{ border-color:var(--orange); color:var(--tomato); }
.cat-opt.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }
.emoji-picker{ display:flex; flex-wrap:wrap; gap:7px; }
.emoji-opt{ width:38px; height:38px; border:1.5px solid #ecdfd2; background:#fff; border-radius:11px; font-size:19px;
  line-height:1; cursor:pointer; transition:.2s; }
.emoji-opt:hover{ border-color:var(--orange); transform:translateY(-2px); }
.emoji-opt.on{ border-color:transparent; background:linear-gradient(140deg,#ffe7d4,#ffcda8); }
.msg{ color:var(--err); font-size:12.5px; min-height:16px; margin-bottom:8px; }
.actions{ display:flex; gap:10px; }
.actions .btn{ flex:1; padding:12px; border:0; border-radius:12px; font-weight:700; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); font-family:inherit; }
.actions .ghost{ flex:1; padding:12px; border:1.5px solid #ecdfd2; border-radius:12px; background:#fff; cursor:pointer;
  font-weight:700; color:var(--muted); font-family:inherit; }

@media (max-width:900px){ .grid{ grid-template-columns:repeat(2,1fr); } }
@media (max-width:560px){
  .home{ padding:16px 14px 100px; }
  .grid{ grid-template-columns:1fr; }
  .slide{ height:118px; padding:0 18px; }
  .slide-emoji{ font-size:40px; }
}
</style>
