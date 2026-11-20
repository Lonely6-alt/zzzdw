<script setup>
import { ref, onMounted, onUnmounted, computed, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { authUser, getToken } from '../composables/useAuth.js'
import { useReviews } from '../composables/useReviews.js'
import { useFavorites } from '../composables/useFavorites.js'
import { useLikes } from '../composables/useLikes.js'
import { useToast } from '../composables/useToast.js'
import { CAT_NAMES, catIcon, catBg, catAccent, catSoft, catPhoto } from '../data/categories.js'

const router = useRouter()
const { toast } = useToast()
const { displayRating, count: reviewCount } = useReviews()
const { isFav, toggle: toggleFavApi } = useFavorites()
const { isLiked, countOf, seed, toggle: toggleLikeApi } = useLikes()

/* ---------------- 状态 ---------------- */
const posts = ref([])
const loading = ref(true)
const failed = ref(false)
const keyword = ref('')
const sortBy = ref('default') // default | hot | rating
const activeTab = ref('hot')  // hot | explore | rank | new

const PAGE_SIZE = 12
const shownCount = ref(PAGE_SIZE)
const loadingMore = ref(false)

const brokenCats = ref(new Set())   // 分类插画加载失败的分类名

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

/* ---------------- Banner ---------------- */
const banners = [
  { title: '秋日探店季 · 满 100 减 30', sub: '精选 20 家新店，探店有礼', emoji: '🍂', cls: 'b1' },
  { title: '新店开张 · 首单 5 折', sub: '限时三天，先到先得', emoji: '🎉', cls: 'b2' },
  { title: '深夜食堂 · 22 点后专享', sub: '夜宵党的专属福利', emoji: '🌙', cls: 'b3' }
]
const bannerIdx = ref(0)
let bannerTimer = null

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
function imgOf(p) {
  // 卡片封面统一用分类卡通插画，不使用真实照片；本地 SVG 加载失败则回退渐变 + emoji
  const photo = catPhoto(p.category)
  return photo && !brokenCats.value.has(p.category) ? photo : ''
}
function onImgError(p) {
  const next = new Set(brokenCats.value)
  next.add(p.category)
  brokenCats.value = next
}

function escapeHtml(s) {
  return (s || '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]))
}
function hl(text) {
  const raw = escapeHtml(text)
  const kw = keyword.value.trim()
  if (!kw) return raw
  const safe = escapeHtml(kw).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  try { return raw.replace(new RegExp(safe, 'gi'), m => `<mark class="hl">${m}</mark>`) }
  catch { return raw }
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

const visible = computed(() => filtered.value.slice(0, shownCount.value))
const hasMore = computed(() => shownCount.value < filtered.value.length)

watch([keyword, activeTab, sortBy], () => { shownCount.value = PAGE_SIZE })

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
    shownCount.value = PAGE_SIZE
  }
}

function loadMore() {
  if (loading.value || loadingMore.value || !hasMore.value) return
  loadingMore.value = true
  // 小延迟让"正在加载"能露出来，同时避免滚动触底时疯狂追加
  setTimeout(() => {
    shownCount.value = Math.min(shownCount.value + PAGE_SIZE, filtered.value.length)
    loadingMore.value = false
  }, 220)
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

function onWindowScroll() {
  if (loading.value || loadingMore.value || !hasMore.value) return
  const doc = document.documentElement
  if (window.innerHeight + window.scrollY >= doc.scrollHeight - 320) loadMore()
}

onMounted(async () => {
  window.addEventListener('touchstart', onTouchStart, { passive: true })
  window.addEventListener('touchmove', onTouchMove, { passive: true })
  window.addEventListener('touchend', onTouchEnd)
  window.addEventListener('scroll', onWindowScroll, { passive: true })
  bannerTimer = setInterval(() => {
    bannerIdx.value = (bannerIdx.value + 1) % banners.length
  }, 4000)
  await loadPosts()
})

onUnmounted(() => {
  window.removeEventListener('touchstart', onTouchStart)
  window.removeEventListener('touchmove', onTouchMove)
  window.removeEventListener('touchend', onTouchEnd)
  window.removeEventListener('scroll', onWindowScroll)
  if (bannerTimer) clearInterval(bannerTimer)
})

/* ---------------- 交互 ---------------- */
function openPost(id) { router.push(`/post/${id}`) }
async function onLike(p) { await toggleLikeApi(p.id, p.likeCount || 0) }
async function onFav(id) { await toggleFavApi(id) }

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
  shownCount.value = PAGE_SIZE
}

/* ---------------- 发布 ---------------- */
const showForm = ref(false)
const form = ref({ title: '', category: '面食控', content: '', emoji: '🍜' })
const formMsg = ref('')
const EMOJI_PICKS = ['🍜', '🍣', '🍔', '🥗', '🍰', '☕', '🍢', '🍲', '🍱', '🥟', '🍡', '🍟']
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
    showForm.value = false
    form.value = { title: '', category: '面食控', content: '', emoji: '🍜' }
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

    <!-- 轮播 Banner -->
    <section class="banner" aria-label="活动banner">
      <div class="banner-track" :style="{ transform: `translateX(-${bannerIdx * 100}%)` }">
        <article v-for="(b, i) in banners" :key="i" class="slide" :class="b.cls">
          <div class="slide-text">
            <h3>{{ b.title }}</h3>
            <p>{{ b.sub }}</p>
          </div>
          <span class="slide-emoji">{{ b.emoji }}</span>
        </article>
      </div>
      <div class="dots">
        <button
          v-for="(b, i) in banners"
          :key="'d' + i"
          type="button"
          class="dot"
          :class="{ on: bannerIdx === i }"
          :aria-label="`第 ${i + 1} 张`"
          @click="bannerIdx = i"
        />
      </div>
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

    <!-- 卡片流：两/三列等宽等高，封面固定 4:3 -->
    <div v-else class="grid">
      <article
        v-for="(p, i) in visible"
        :key="p.id"
        class="card"
        :style="{ '--ac': catAccent(p.category), '--i': i }"
        @click="openPost(p.id)"
      >
        <div class="cover" :style="{ background: catBg(p.category) }">
          <img
            v-if="imgOf(p)"
            :src="imgOf(p)"
            :alt="p.title"
            loading="lazy"
            decoding="async"
            @error="onImgError(p)"
          />
          <div v-else class="cover-fallback">
            <span class="cover-glow"></span>
            <span class="cover-emoji">{{ p.emoji || catIcon(p.category) }}</span>
          </div>
          <span class="cover-shade"></span>
          <span class="cover-cat">{{ catIcon(p.category) }} {{ p.category }}</span>

          <button
            class="fav-btn"
            :class="{ on: isFav(p.id) }"
            type="button"
            :title="isFav(p.id) ? '取消收藏' : '收藏'"
            @click.stop="onFav(p.id)"
          >{{ isFav(p.id) ? '★' : '☆' }}</button>
        </div>

        <div class="card-body">
          <h3 class="shop">{{ shopName(p) }}</h3>
          <p class="line" v-html="hl(p.title)"></p>
          <div class="meta">
            <button class="like" :class="{ on: isLiked(p.id) }" type="button" @click.stop="onLike(p)">
              {{ isLiked(p.id) ? '❤️' : '🤍' }}<i>{{ likesOf(p) }}</i>
            </button>
            <span class="cmt" @click.stop="openPost(p.id)">💬 {{ p.reviewCount || 0 }}</span>
          </div>
        </div>
      </article>
    </div>

    <!-- 加载更多 / 到底 -->
    <div v-if="!loading && !failed && filtered.length" class="more">
      <span v-if="loadingMore" class="more-loading"><span class="spinner sm"></span>正在加载更多…</span>
      <span v-else-if="!hasMore" class="more-end">— 已经到底啦，去看看别的标签 —</span>
      <span v-else class="more-tip">继续上滑加载更多</span>
    </div>

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

/* ===== Banner ===== */
.banner{ position:relative; overflow:hidden; border-radius:20px; margin-bottom:18px; box-shadow:0 12px 28px rgba(255,90,60,.16); }
.banner-track{ display:flex; transition:transform .55s cubic-bezier(.4,0,.2,1); }
.slide{ flex:0 0 100%; height:132px; display:flex; align-items:center; gap:16px; padding:0 26px; color:#fff; }
.slide.b1{ background:linear-gradient(120deg,#ff8a4c,#ff5f3d); }
.slide.b2{ background:linear-gradient(120deg,#ffb26b,#ff8a3d); }
.slide.b3{ background:linear-gradient(120deg,#ff7e5f,#feb47b); }
.slide-text{ flex:1; min-width:0; }
.slide-text h3{ font-size:17px; font-weight:800; text-shadow:0 2px 8px rgba(120,30,10,.22); }
.slide-text p{ font-size:12.5px; opacity:.92; margin-top:6px; }
.slide-emoji{ font-size:48px; filter:drop-shadow(0 8px 12px rgba(120,40,20,.28)); }
.dots{ position:absolute; left:26px; bottom:12px; display:flex; gap:6px; }
.dot{ width:6px; height:6px; padding:0; border:0; border-radius:50%; background:rgba(255,255,255,.45); cursor:pointer; transition:.25s; }
.dot.on{ width:16px; border-radius:3px; background:#fff; }

/* 下拉刷新 */
.pull-tip{ display:flex; align-items:center; justify-content:center; font-size:12px; color:var(--muted); overflow:hidden; transition:height .1s; }

/* ===== 卡片流 ===== */
.grid{ display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.card{ background:#fff; border:1.5px solid #f6ebe0; border-radius:18px; overflow:hidden; cursor:pointer;
  box-shadow:0 8px 20px rgba(255,120,80,.07); transition:transform .22s, box-shadow .22s, border-color .22s;
  animation:cardIn .4s backwards; animation-delay:calc(var(--i,0) * 32ms); }
@keyframes cardIn{ from{ opacity:0; transform:translateY(10px); } to{ opacity:1; transform:translateY(0); } }
.card:hover{ transform:translateY(-5px); box-shadow:0 18px 34px rgba(255,90,60,.16); border-color:#ffd9bf; }

.cover{ position:relative; width:100%; aspect-ratio:4 / 3; overflow:hidden;
  display:flex; align-items:center; justify-content:center; }
.cover img{ width:100%; height:100%; object-fit:cover; display:block; transition:transform .45s ease; }
.card:hover .cover img{ transform:scale(1.08); }
/* 无实拍图时的美化兜底：柔光圆斑 + 玻璃底座 + emoji */
.cover-fallback{ position:absolute; inset:0; display:flex; align-items:center; justify-content:center; overflow:hidden; }
.cover-glow{ position:absolute; width:150px; height:150px; border-radius:50%;
  background:radial-gradient(circle,rgba(255,255,255,.75),rgba(255,255,255,0) 70%); }
.cover-emoji{ position:relative; font-size:58px; line-height:1; padding:18px; border-radius:50%;
  background:rgba(255,255,255,.55); box-shadow:0 10px 26px rgba(160,90,50,.18), inset 0 0 0 1.5px rgba(255,255,255,.7);
  backdrop-filter:blur(2px); transition:transform .35s; }
.card:hover .cover-emoji{ transform:scale(1.12) rotate(-5deg); }
/* 底部渐变压暗，让分类角标清晰 */
.cover-shade{ position:absolute; inset:0; pointer-events:none;
  background:linear-gradient(to top,rgba(60,30,15,.42),rgba(60,30,15,0) 42%); }
.cover-cat{ position:absolute; left:10px; bottom:9px; z-index:2; pointer-events:none;
  font-size:11px; font-weight:700; color:#fff; letter-spacing:.2px;
  padding:3px 9px; border-radius:999px; background:rgba(40,20,10,.34); backdrop-filter:blur(4px); }
.fav-btn{ position:absolute; top:10px; right:10px; width:30px; height:30px; border-radius:50%; border:0; cursor:pointer;
  font-size:14px; line-height:1; color:#a98f78; background:rgba(255,255,255,.92); transition:.2s; }
.fav-btn:hover{ transform:scale(1.1); color:var(--orange); }
.fav-btn.on{ color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 5px 12px rgba(255,90,60,.32); }

.card-body{ padding:11px 13px 12px; min-height:88px; display:flex; flex-direction:column; }
.shop{ font-size:13.5px; font-weight:800; color:var(--ink); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.line{ font-size:12.5px; color:#9b8c7e; line-height:1.5; margin-top:4px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.meta{ display:flex; align-items:center; gap:12px; margin-top:auto; padding-top:9px; }
.like{ display:flex; align-items:center; gap:4px; border:0; background:transparent; cursor:pointer;
  font-size:12px; color:var(--muted); padding:0; font-family:inherit; transition:.15s; }
.like:hover{ color:var(--tomato); }
.like i{ font-style:normal; font-weight:700; }
.like.on{ color:var(--tomato); }
.like.on{ animation:pop .3s ease; }
@keyframes pop{ 0%{ transform:scale(1); } 45%{ transform:scale(1.18); } 100%{ transform:scale(1); } }
.cmt{ font-size:12px; color:var(--muted); cursor:pointer; }
.cmt:hover{ color:var(--tomato); }

/* 加载更多 */
.more{ display:flex; justify-content:center; align-items:center; gap:8px; padding:22px 0 4px; font-size:12.5px; color:#c4ab94; }
.more-loading{ display:flex; align-items:center; gap:7px; color:var(--muted); }
.spinner{ width:26px; height:26px; border-radius:50%; border:3px solid #f0e6db; border-top-color:var(--tomato); animation:spin .8s linear infinite; }
.spinner.sm{ width:14px; height:14px; border-width:2px; }

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
