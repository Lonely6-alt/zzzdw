<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { authUser, logout } from '../composables/useAuth.js'
import { useReviews } from '../composables/useReviews.js'
import { useOrder } from '../composables/useOrder.js'
import { useFavorites } from '../composables/useFavorites.js'
import { CAT_NAMES, CATEGORIES, catIcon, catBg } from '../data/categories.js'

const route = useRoute()
const router = useRouter()
const { allReviews, avgRating, count: reviewCount } = useReviews()
const { openOrder } = useOrder()
const { isFav, toggle } = useFavorites()

const posts = ref([])
const activeCat = ref('全部')
const keyword = ref('')
const loading = ref(false)
const sortBy = ref('new') // new | hot | rating

// 顶部导航栏锚点
const gridEl = ref(null)
function goHome() { router.push('/'); window.scrollTo({ top: 0, behavior: 'smooth' }) }
// 搜索结果锚点（页内滚动）
function goResults() { gridEl.value?.scrollIntoView({ behavior: 'smooth', block: 'start' }) }
// 「发现」是独立页面，内容和首页不同，不再复用首页列表
function goDiscover() { router.push('/discover') }
function goProfile() { router.push('/profile') }

// 热搜词（固定示例）
const hotWords = ['拉面', '寿司', '炸鸡', '抹茶', '拿铁', '火锅', '轻食']

const EMOJI_PICKS = ['🍜', '🍣', '🍔', '🥗', '🍰', '☕', '🍢', '🍲', '🍱', '🥟', '🍡', '🍟']

// 搜索 + 排序：纯前端过滤，不改动后端接口
const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  const list = posts.value.filter(p => {
    const catOk = activeCat.value === '全部' || p.category === activeCat.value
    if (!catOk) return false
    if (!kw) return true
    return (
      (p.title || '').toLowerCase().includes(kw) ||
      (p.content || '').toLowerCase().includes(kw) ||
      (p.author || '').toLowerCase().includes(kw) ||
      (p.category || '').toLowerCase().includes(kw)
    )
  })
  const arr = [...list]
  if (sortBy.value === 'hot') {
    arr.sort((a, b) => reviewCount(b.id) - reviewCount(a.id) || b.id - a.id)
  } else if (sortBy.value === 'rating') {
    arr.sort((a, b) => avgRating(b.id) - avgRating(a.id) || reviewCount(b.id) - reviewCount(a.id))
  } else {
    arr.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt) || b.id - a.id)
  }
  return arr
})

// 今日精选：好评优先，无评价时回退到最新
const featured = computed(() => {
  const rated = [...posts.value].filter(p => reviewCount(p.id) > 0)
  const pool = rated.length >= 3 ? rated : [...posts.value]
  return pool
    .sort((a, b) => avgRating(b.id) - avgRating(a.id) || reviewCount(b.id) - reviewCount(a.id) || b.id - a.id)
    .slice(0, 3)
})

const stats = computed(() => ({
  posts: posts.value.length,
  authors: new Set(posts.value.map(p => p.author)).size,
  reviews: allReviews().length,
  cats: CAT_NAMES.length
}))

async function loadPosts() {
  loading.value = true
  try {
    const r = await fetch('/api/posts')
    posts.value = await r.json()
  } finally {
    loading.value = false
  }
}

// 发布（沿用已有后端接口）
const showForm = ref(false)
const form = ref({ title: '', category: '面食控', content: '', emoji: '🍜' })
const formMsg = ref('')
async function publish() {
  formMsg.value = ''
  if (!form.value.title.trim()) { formMsg.value = '先给这道美食起个名字吧～'; return }
  if (!form.value.content.trim()) { formMsg.value = '再写两句味道和心得吧～'; return }
  try {
    const r = await fetch('/api/posts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${localStorage.getItem('food_token')}`
      },
      body: JSON.stringify(form.value)
    })
    const data = await r.json().catch(() => ({}))
    if (!r.ok) { formMsg.value = data.message || '发布失败'; return }
    showForm.value = false
    form.value = { title: '', category: '面食控', content: '', emoji: '🍜' }
    await loadPosts()
  } catch (e) {
    formMsg.value = '网络错误'
  }
}

function openPost(id) { router.push(`/post/${id}`) }
function onOrder(p) { openOrder(p) }
function onFav(id) { toggle(id) }
function onLogout() { logout(); router.push('/login') }

// 搜索关键字高亮：先转义防 XSS，再把命中片段包裹成 <mark>
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

// 首页「热门点评」：联动评价数据，让广场内容更丰富
const hotReviews = computed(() => {
  const list = allReviews().sort((a, b) => b.at - a.at).slice(0, 6)
  return list
    .map(r => {
      const p = posts.value.find(x => x.id === r.postId)
      return p ? { ...r, title: p.title, emoji: p.emoji, category: p.category } : null
    })
    .filter(Boolean)
})
function starStr(n) {
  const f = Math.round(n)
  return '★'.repeat(f) + '☆'.repeat(5 - f)
}
const firstChar = s => (s || '?').trim().charAt(0).toUpperCase()

onMounted(async () => {
  await loadPosts()
  const c = route.query.cat
  if (typeof c === 'string' && CATEGORIES.includes(c)) activeCat.value = c
})
</script>

<template>
  <div class="home">
    <!-- 背景漂浮装饰，呼应登录页 -->
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>

    <!-- 顶部导航栏：呼应登录页玻璃质感 + 胶囊导航 -->
    <nav class="navbar">
      <div class="nav-brand" @click="goHome">
        <span class="brand-logo">🍲</span>
        <span class="brand-text">食光<em>美食社区</em></span>
      </div>
      <div class="nav-links">
        <button class="on" @click="goHome">首页</button>
        <button @click="goDiscover">发现</button>
        <button @click="router.push('/map')">地图</button>
        <button @click="router.push('/ranking')">排名</button>
        <button @click="goProfile">我的</button>
      </div>
      <div class="nav-right">
        <span class="nav-user" v-if="authUser">👤 {{ authUser }}</span>
        <button class="nav-out" @click="onLogout">退出</button>
      </div>
    </nav>

    <!-- 顶部横幅：渐变 Hero + 数据概览 -->
    <section class="hero">
      <div class="hero-top">
        <div class="hero-copy">
          <span class="hero-badge">🎉 今日上新 · {{ stats.posts }} 道好味道</span>
          <h1>发现城市里的<br />每一口好味道</h1>
          <p class="hero-sub">记录 · 分享 · 收藏你的私藏美食地图</p>

          <div class="searchbar">
            <span class="ic">🔍</span>
            <input v-model="keyword" placeholder="搜索美食、店铺或口味…" />
            <button v-if="keyword" class="clear" type="button" @click="keyword = ''" aria-label="清空">✕</button>
            <button class="go" type="button" @click="goResults">搜索</button>
          </div>

          <div class="hotwords">
            <span class="hw-label">大家都在搜</span>
            <button v-for="w in hotWords" :key="w" type="button" @click="keyword = w">{{ w }}</button>
          </div>

          <p v-if="authUser" class="welcome">Hi，{{ authUser }} 👋 今天想吃点什么？</p>
        </div>

        <div class="hero-art" aria-hidden="true">
          <span class="tile t1">🍜</span>
          <span class="tile t2">🍣</span>
          <span class="tile t3">🍔</span>
          <span class="tile t4">🥗</span>
          <span class="tile t5">🍰</span>
          <span class="tile t6">☕</span>
        </div>
      </div>

      <div class="hero-stats">
        <div class="hs"><b>{{ stats.posts }}</b><span>篇美食笔记</span></div>
        <div class="hs"><b>{{ stats.authors }}</b><span>位吃货分享者</span></div>
        <div class="hs"><b>{{ stats.reviews }}</b><span>条真实点评</span></div>
        <div class="hs"><b>{{ stats.cats }}</b><span>大美食分类</span></div>
      </div>
    </section>

    <!-- 今日精选 -->
    <section class="featured" v-if="!loading && featured.length">
      <div class="sec-head">
        <h2>🔥 今日精选</h2>
        <span class="sec-sub">编辑部私藏的 {{ featured.length }} 道，闭眼点不踩雷</span>
      </div>
      <div class="feat-list">
        <article
          v-for="p in featured"
          :key="'f' + p.id"
          class="feat-card"
          @click="openPost(p.id)"
        >
          <div class="feat-emoji" :style="{ background: catBg(p.category) }">{{ p.emoji }}</div>
          <div class="feat-body">
            <span class="feat-cat">{{ p.category }}</span>
            <h3 v-html="hl(p.title)"></h3>
            <p class="feat-excerpt" v-html="hl(p.content)"></p>
            <div class="feat-foot">
              <span class="stars">{{ starStr(avgRating(p.id)) }}</span>
              <span class="score">{{ avgRating(p.id) ? avgRating(p.id).toFixed(1) : '暂无评分' }}</span>
              <span class="author">@{{ p.author }}</span>
            </div>
          </div>
        </article>
      </div>
    </section>

    <!-- 内容工具条：结果数 + 排序 -->
    <div class="toolbar" ref="gridEl">
      <div class="tb-left">
        <h2>
          {{ activeCat === '全部' ? '全部好味道' : activeCat }}
          <em>共 {{ filtered.length }} 道</em>
        </h2>
        <span v-if="keyword.trim()" class="tb-kw">关键词「{{ keyword.trim() }}」</span>
      </div>
      <div class="tb-sort">
        <button :class="{ on: sortBy === 'new' }" @click="sortBy = 'new'">🆕 最新</button>
        <button :class="{ on: sortBy === 'hot' }" @click="sortBy = 'hot'">🔥 人气</button>
        <button :class="{ on: sortBy === 'rating' }" @click="sortBy = 'rating'">⭐ 好评</button>
      </div>
    </div>

    <!-- 骨架屏 -->
    <div v-if="loading" class="grid">
      <div v-for="n in 6" :key="'sk' + n" class="sk-card">
        <div class="sk-cover"></div>
        <div class="sk-line w80"></div>
        <div class="sk-line w60"></div>
        <div class="sk-line w40"></div>
      </div>
    </div>

    <div v-else-if="!filtered.length" class="empty">
      <div class="empty-emoji">🍽️</div>
      <p class="empty-title">没有找到相关美食</p>
      <p class="hint">换个关键词或分类试试，或点击下方按钮分享你的私藏～</p>
      <button class="empty-btn" type="button" @click="showForm = true">＋ 发布一道美食</button>
    </div>

    <div v-else class="grid">
      <article
        v-for="(p, index) in filtered"
        :key="p.id"
        class="card"
        :style="{ '--i': index }"
        @click="openPost(p.id)"
      >
        <div class="card-cover" :style="{ background: catBg(p.category) }">
          <span class="cover-emoji">{{ p.emoji }}</span>
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
          <h3 v-html="hl(p.title)"></h3>
          <p class="excerpt" v-html="hl(p.content)"></p>

          <div class="card-foot">
            <span class="avatar">{{ firstChar(p.author) }}</span>
            <span class="foot-author">@{{ p.author }}</span>
            <span class="foot-rate">
              <span class="stars">{{ starStr(avgRating(p.id)) }}</span>
              <em>{{ avgRating(p.id) ? avgRating(p.id).toFixed(1) : '暂无' }}</em>
              <i>💬 {{ reviewCount(p.id) }}</i>
            </span>
          </div>

          <div class="card-actions">
            <button class="mini" type="button" @click.stop="openPost(p.id)">看详情</button>
            <button class="mini primary" type="button" @click.stop="onOrder(p)">立即点单</button>
          </div>
        </div>
      </article>
    </div>

    <!-- 热门点评：联动评价数据，让首页更丰富 -->
    <section class="feed" v-if="hotReviews.length">
      <div class="sec-head">
        <h2>💬 热门点评</h2>
        <span class="sec-sub">来自食客们的真实声音</span>
      </div>
      <div class="feed-list">
        <article v-for="r in hotReviews" :key="r.id" class="feed-card" @click="openPost(r.postId)">
          <div class="feed-emoji">{{ r.emoji }}</div>
          <div class="feed-body">
            <div class="feed-top">
              <span class="feed-name">{{ r.title }}</span>
              <span class="feed-stars">{{ starStr(r.rating) }}</span>
            </div>
            <p class="feed-comment">{{ r.comment }}</p>
            <div class="feed-by">@{{ r.author }} · {{ r.category }}</div>
          </div>
        </article>
      </div>
    </section>

    <!-- 发布入口 -->
    <button class="fab" type="button" @click="showForm = true" title="发布美食">＋</button>

    <!-- 发布弹窗 -->
    <div v-if="showForm" class="modal" @click.self="showForm = false">
      <div class="sheet">
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
.home{ position:relative; max-width:1040px; margin:0 auto; padding:24px 24px 96px; z-index:1; }

/* ============ 顶部导航栏 ============ */
.navbar{
  position:sticky; top:12px; z-index:12;
  display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap;
  padding:10px 16px; margin-bottom:20px;
  background:rgba(255,247,238,.82); backdrop-filter:blur(10px);
  border:1.5px solid #f0e6db; border-radius:18px;
  box-shadow:0 8px 20px rgba(255,90,60,.08);
}
.nav-brand{ display:flex; align-items:center; gap:10px; cursor:pointer; }
.brand-logo{
  width:34px; height:34px; border-radius:11px; display:flex; align-items:center; justify-content:center;
  font-size:18px; background:linear-gradient(140deg,#ffe7d4,#ffc9a3); box-shadow:inset 0 0 0 1px rgba(255,255,255,.6);
}
.brand-text{ font-weight:800; font-size:17px; display:flex; flex-direction:column; line-height:1.15; }
.brand-text em{ font-style:normal; font-size:10.5px; font-weight:600; color:var(--muted); letter-spacing:1.5px; }
.nav-links{ display:flex; gap:6px; }
.nav-links button{
  border:0; background:transparent; color:var(--muted); font-weight:600; font-size:14px;
  padding:8px 16px; border-radius:999px; cursor:pointer; transition:.2s;
}
.nav-links button:hover{ color:var(--orange); background:#fff0ea; }
.nav-links button.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); color:#fff;
  box-shadow:0 6px 14px rgba(255,90,60,.28); }
.nav-right{ display:flex; align-items:center; gap:10px; }
.nav-user{ font-size:13px; color:var(--muted); }
.nav-out{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:7px 14px; border-radius:11px; cursor:pointer; font-weight:600; font-size:13px; transition:.2s; }
.nav-out:hover{ color:var(--err); border-color:var(--err); }
@media (max-width:640px){ .nav-links{ order:3; width:100%; justify-content:center; } }

/* ============ 背景漂浮装饰 ============ */
.bg-orbs{ position:absolute; inset:0; pointer-events:none; z-index:0; }
.bg-orbs span{ position:absolute; font-size:40px; opacity:.15; animation:orb 9s ease-in-out infinite; filter:blur(.3px); }
.o1{ left:4%;  top:12%; } .o2{ left:82%; top:10%; animation-delay:.8s; }
.o3{ left:10%; top:70%; animation-delay:1.6s; } .o4{ left:88%; top:66%; animation-delay:2.4s; }
.o5{ left:44%; top:6%;  animation-delay:3.2s; } .o6{ left:62%; top:82%; animation-delay:1.1s; }
.o7{ left:26%; top:40%; animation-delay:2.7s; font-size:54px; } .o8{ left:72%; top:44%; animation-delay:3.6s; }
@keyframes orb{ 0%,100%{ transform:translateY(0) rotate(-6deg); } 50%{ transform:translateY(-22px) rotate(8deg); } }

/* ============ 渐变 Hero ============ */
.hero{
  position:relative; overflow:hidden; z-index:1;
  background:linear-gradient(135deg,#ff9a52 0%,#ff5f3d 48%,#e0333c 100%);
  border-radius:26px; padding:32px 34px 22px; color:#fff;
  box-shadow:var(--ring);
}
.hero::before{
  content:""; position:absolute; inset:0; pointer-events:none;
  background:
    radial-gradient(circle at 84% 8%,rgba(255,255,255,.30),transparent 42%),
    radial-gradient(circle at 6% 96%,rgba(255,214,150,.30),transparent 45%);
}
.hero-top{ position:relative; z-index:2; display:flex; align-items:center; gap:26px; }
.hero-copy{ flex:1; min-width:0; }
.hero-badge{
  display:inline-block; font-size:12px; font-weight:700;
  background:rgba(255,255,255,.2); border:1px solid rgba(255,255,255,.32);
  padding:5px 12px; border-radius:999px; margin-bottom:14px;
}
.hero-copy h1{ font-size:32px; line-height:1.24; font-weight:800; letter-spacing:.5px; }
.hero-sub{ margin-top:10px; font-size:14.5px; opacity:.92; }

/* 搜索栏 */
.searchbar{
  display:flex; align-items:center; gap:10px;
  margin-top:20px; max-width:560px;
  background:#fff; border-radius:999px; padding:6px 6px 6px 18px;
  box-shadow:0 12px 26px rgba(140,30,10,.22);
}
.searchbar .ic{ font-size:17px; opacity:.5; }
.searchbar input{
  flex:1; min-width:0; border:0; outline:none; background:transparent;
  font-size:15px; color:var(--ink); font-family:inherit; padding:9px 0;
}
.searchbar .clear{
  border:0; background:#f0e6db; color:var(--muted); cursor:pointer;
  width:24px; height:24px; border-radius:50%; font-size:12px; line-height:1; flex-shrink:0;
}
.searchbar .clear:hover{ background:#e7ddd2; }
.searchbar .go{
  flex-shrink:0; border:0; cursor:pointer; font-weight:800; font-size:14px; color:#fff;
  padding:10px 22px; border-radius:999px;
  background:linear-gradient(120deg,#ff7a3d,#e23b3b);
  box-shadow:0 6px 14px rgba(226,59,59,.35); transition:.2s;
}
.searchbar .go:hover{ filter:brightness(1.06); }

/* 热搜词 */
.hotwords{ display:flex; align-items:center; gap:8px; flex-wrap:wrap; margin-top:14px; position:relative; z-index:2; }
.hw-label{ font-size:12px; opacity:.78; }
.hotwords button{
  border:1px solid rgba(255,255,255,.4); background:rgba(255,255,255,.14); color:#fff;
  font-size:12.5px; padding:5px 12px; border-radius:999px; cursor:pointer; transition:.2s; font-family:inherit;
}
.hotwords button:hover{ background:rgba(255,255,255,.3); }

.welcome{ margin-top:14px; font-size:13.5px; opacity:.95; }

/* Hero 右侧图标墙 */
.hero-art{ flex-shrink:0; display:grid; grid-template-columns:repeat(3,1fr); gap:10px; width:202px; }
.tile{
  aspect-ratio:1; display:flex; align-items:center; justify-content:center; font-size:26px;
  background:rgba(255,255,255,.16); border:1px solid rgba(255,255,255,.3);
  border-radius:16px; backdrop-filter:blur(3px);
  animation:floatTile 6s ease-in-out infinite;
}
.t1{ animation-delay:0s; } .t2{ animation-delay:.4s; } .t3{ animation-delay:.8s; }
.t4{ animation-delay:1.2s; } .t5{ animation-delay:1.6s; } .t6{ animation-delay:2s; }
@keyframes floatTile{ 0%,100%{ transform:translateY(0) rotate(-3deg); } 50%{ transform:translateY(-9px) rotate(4deg); } }

/* Hero 数据概览 */
.hero-stats{
  position:relative; z-index:2; display:grid; grid-template-columns:repeat(4,1fr); gap:12px;
  margin-top:24px; padding-top:18px; border-top:1px solid rgba(255,255,255,.3);
}
.hs b{ display:block; font-size:23px; font-weight:800; letter-spacing:.5px; }
.hs span{ font-size:12.5px; opacity:.88; }
@media (max-width:820px){
  .hero-art{ display:none; }
  .hero-copy h1{ font-size:27px; }
}
@media (max-width:520px){
  .hero{ padding:26px 20px 18px; }
  .hero-stats{ grid-template-columns:repeat(2,1fr); row-gap:16px; }
}

/* ============ 区块标题 ============ */
.sec-head{ display:flex; align-items:baseline; gap:12px; flex-wrap:wrap; margin-bottom:14px; }
.sec-head h2{ font-size:20px; font-weight:800; }
.sec-sub{ font-size:12.5px; color:var(--muted); }

/* ============ 今日精选 ============ */
.featured{ position:relative; z-index:1; margin-top:22px; }
.feat-list{ display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.feat-card{
  display:flex; gap:13px; background:#fff; border-radius:18px; padding:15px; cursor:pointer;
  border:1.5px solid #f6ebe0; box-shadow:0 10px 24px rgba(255,120,80,.08);
  transition:transform .2s, box-shadow .2s; animation:cardIn .45s backwards;
}
.feat-card:hover{ transform:translateY(-4px); box-shadow:0 16px 32px rgba(255,90,60,.18); border-color:#ffd9bf; }
.feat-emoji{
  flex-shrink:0; width:58px; height:58px; border-radius:16px; display:flex; align-items:center; justify-content:center;
  font-size:30px; box-shadow:inset 0 0 0 1px rgba(255,255,255,.7);
}
.feat-body{ min-width:0; }
.feat-cat{ font-size:11px; font-weight:700; color:var(--tomato); background:#fff0ea; padding:2px 9px; border-radius:9px; }
.feat-body h3{ font-size:15px; margin:7px 0 5px; line-height:1.35; }
.feat-excerpt{ font-size:12.5px; color:var(--muted); line-height:1.55;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.feat-foot{ display:flex; align-items:center; gap:7px; margin-top:9px; font-size:12px; }
.feat-foot .author{ color:#bba; margin-left:auto; }
.stars{ color:#f5a623; letter-spacing:.5px; }
.score{ color:var(--tomato); font-weight:800; }
@media (max-width:900px){ .feat-list{ grid-template-columns:1fr; } }

/* ============ 工具条 ============ */
.toolbar{
  position:relative; z-index:1; display:flex; align-items:center; justify-content:space-between;
  gap:14px; flex-wrap:wrap; margin:28px 0 14px; scroll-margin-top:80px;
}
.tb-left{ display:flex; align-items:baseline; gap:10px; flex-wrap:wrap; }
.tb-left h2{ font-size:20px; font-weight:800; }
.tb-left h2 em{ font-style:normal; font-size:13px; font-weight:600; color:var(--muted); margin-left:6px; }
.tb-kw{ font-size:12.5px; color:var(--tomato); background:#fff0ea; padding:3px 10px; border-radius:999px; }
.tb-sort{ display:flex; gap:6px; background:#fdf4ea; padding:5px; border-radius:14px; border:1px solid #f4e7d9; }
.tb-sort button{
  border:0; background:transparent; color:#8a7a6d; font-size:12.5px; font-weight:700;
  padding:6px 13px; border-radius:10px; cursor:pointer; transition:.2s; font-family:inherit;
}
.tb-sort button:hover{ color:var(--tomato); }
.tb-sort button.on{ background:#fff; color:var(--tomato); box-shadow:0 3px 9px rgba(255,120,80,.18); }

/* ============ 卡片网格 ============ */
.grid{ position:relative; z-index:1; display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.card{
  background:#fff; border-radius:18px; overflow:hidden; cursor:pointer;
  border:1.5px solid #f6ebe0;
  box-shadow:0 10px 24px rgba(255,120,80,.07);
  transition:transform .22s, box-shadow .22s, border-color .22s;
  display:flex; flex-direction:column;
  animation:cardIn .45s backwards; animation-delay:calc(var(--i, 0) * 45ms);
}
@keyframes cardIn{ from{ opacity:0; transform:translateY(14px); } to{ opacity:1; transform:translateY(0); } }
.card:hover{ transform:translateY(-5px); box-shadow:0 18px 34px rgba(255,90,60,.18); border-color:#ffd9bf; }
.card-cover{ position:relative; height:116px; display:flex; align-items:center; justify-content:center; }
.card-cover::after{
  content:""; position:absolute; inset:0;
  background:radial-gradient(circle at 78% 22%,rgba(255,255,255,.85),transparent 58%);
}
.cover-emoji{
  position:relative; z-index:2; font-size:48px; line-height:1;
  filter:drop-shadow(0 8px 12px rgba(160,90,50,.22)); transition:transform .25s;
}
.card:hover .cover-emoji{ transform:scale(1.14) rotate(-5deg); }
.cover-cat{
  position:absolute; z-index:2; left:11px; bottom:10px;
  font-size:11px; font-weight:700; color:#7e5a3e;
  background:rgba(255,255,255,.82); padding:3px 9px; border-radius:9px;
  backdrop-filter:blur(3px);
}
.fav-btn{
  position:absolute; z-index:3; top:10px; right:10px; width:30px; height:30px; border-radius:50%;
  border:0; cursor:pointer; font-size:14px; line-height:1; color:#bda995;
  background:rgba(255,255,255,.82); transition:.2s;
}
.fav-btn:hover{ transform:scale(1.1); color:var(--orange); }
.fav-btn.on{ color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato));
  box-shadow:0 6px 14px rgba(255,90,60,.35); }

.card-body{ padding:13px 15px 15px; display:flex; flex-direction:column; flex:1; }
.card-body h3{ font-size:15.5px; line-height:1.4; margin-bottom:6px; }
.excerpt{ font-size:12.8px; color:var(--muted); line-height:1.6;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }

.card-foot{ display:flex; align-items:center; gap:6px; margin-top:11px; font-size:12px; color:#bba; }
.avatar{
  width:22px; height:22px; border-radius:50%; flex-shrink:0;
  display:flex; align-items:center; justify-content:center;
  font-size:11px; font-weight:800; color:#8a4b22;
  background:linear-gradient(140deg,#ffe0c8,#ffbe90);
}
.foot-author{ white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:82px; }
.foot-rate{ margin-left:auto; display:flex; align-items:center; gap:5px; flex-shrink:0; }
.foot-rate em{ font-style:normal; font-weight:800; color:var(--tomato); }
.foot-rate i{ font-style:normal; color:#c4b3a4; }

.card-actions{ display:flex; gap:8px; margin-top:12px; }
.mini{
  flex:1; border:1.5px solid #f0e2d4; background:#fff; color:var(--muted);
  padding:8px 0; border-radius:11px; font-size:12.5px; font-weight:700;
  cursor:pointer; transition:.2s; font-family:inherit;
}
.mini:hover{ border-color:var(--orange); color:var(--tomato); }
.mini.primary{
  border-color:transparent; color:#fff;
  background:linear-gradient(120deg,var(--orange),var(--tomato));
  box-shadow:0 6px 14px rgba(255,90,60,.26);
}
.mini.primary:hover{ filter:brightness(1.05); color:#fff; }

@media (max-width:760px){ .grid{ grid-template-columns:repeat(2,1fr); } }
@media (max-width:480px){
  .grid{ grid-template-columns:1fr; }
  .nav-user{ display:none; }
}

/* ============ 骨架屏 ============ */
.sk-card{ background:#fff; border-radius:18px; padding:0 0 16px; overflow:hidden; border:1.5px solid #f6ebe0; }
.sk-cover{ height:116px; background:#f6eee6; }
.sk-line{ height:11px; border-radius:6px; margin:12px 15px 0; background:#f4ece4;
  animation:shimmer 1.4s ease-in-out infinite; }
.sk-line.w80{ width:80%; } .sk-line.w60{ width:60%; } .sk-line.w40{ width:40%; }
@keyframes shimmer{ 0%,100%{ opacity:1; } 50%{ opacity:.45; } }

/* ============ 空状态 ============ */
.empty{ position:relative; z-index:1; text-align:center; padding:44px 20px 10px; }
.empty-emoji{ font-size:54px; animation:floaty 3s ease-in-out infinite; }
.empty-title{ font-size:17px; font-weight:800; margin:12px 0 6px; }
.hint{ position:relative; z-index:1; color:var(--muted); text-align:center; }
.empty-btn{ margin-top:16px; border:0; border-radius:12px; padding:11px 20px; font-weight:700; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 8px 18px rgba(255,90,60,.3); }
.empty-btn:hover{ filter:brightness(1.04); }
@keyframes floaty{ 0%,100%{ transform:translateY(0); } 50%{ transform:translateY(-8px); } }

/* 关键词高亮（v-html 内容需用 :deep 才能命中） */
:deep(.hl){ background:linear-gradient(120deg,#ffe08a,#ffd166); color:#5a3b00;
  border-radius:4px; padding:0 2px; font-weight:700; }

/* ============ 热门点评 ============ */
.feed{ position:relative; z-index:1; margin-top:36px; }
.feed-list{ display:grid; grid-template-columns:repeat(2,1fr); gap:14px; }
.feed-card{ display:flex; gap:12px; background:#fff; border-radius:16px; padding:14px; cursor:pointer;
  border:1.5px solid #f6ebe0; box-shadow:0 8px 20px rgba(255,120,80,.07);
  transition:transform .2s, box-shadow .2s, border-color .2s; animation:cardIn .45s backwards; }
.feed-card:hover{ transform:translateY(-3px); box-shadow:0 14px 28px rgba(255,90,60,.16); border-color:#ffd9bf; }
.feed-emoji{ font-size:32px; flex-shrink:0; }
.feed-body{ min-width:0; }
.feed-top{ display:flex; align-items:center; gap:8px; }
.feed-name{ font-size:15px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.feed-stars{ font-size:12px; color:#f5a623; flex-shrink:0; }
.feed-comment{ font-size:13px; color:var(--muted); line-height:1.6; margin:6px 0; display:-webkit-box;
  -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.feed-by{ font-size:12px; color:#bba; }
@media (max-width:640px){ .feed-list{ grid-template-columns:1fr; } }

/* ============ 发布按钮 ============ */
.fab{
  position:fixed; right:24px; bottom:24px; z-index:15;
  width:56px; height:56px; border:0; border-radius:50%; cursor:pointer;
  font-size:27px; color:#fff; line-height:1;
  background:linear-gradient(120deg,var(--orange),var(--tomato));
  box-shadow:0 12px 26px rgba(255,90,60,.42); transition:.2s;
}
.fab:hover{ transform:translateY(-3px) rotate(90deg); }

/* ============ 发布弹窗 ============ */
.modal{ position:fixed; inset:0; background:rgba(40,20,10,.45); display:flex; align-items:center;
  justify-content:center; padding:20px; z-index:20; animation:mfade .2s ease; }
@keyframes mfade{ from{ opacity:0; } to{ opacity:1; } }
.sheet{ background:#fff; border-radius:20px; padding:24px; width:min(460px,100%); max-height:90vh; overflow:auto;
  box-shadow:0 24px 60px rgba(0,0,0,.28); animation:mpop .26s cubic-bezier(.2,.9,.3,1.2); }
@keyframes mpop{ from{ opacity:0; transform:translateY(16px) scale(.97); } to{ opacity:1; transform:translateY(0) scale(1); } }
.sheet h3{ font-size:19px; font-weight:800; }
.sheet-sub{ font-size:12.5px; color:var(--muted); margin:5px 0 16px; }
.field{ margin-bottom:14px; }
.field label{ display:block; font-size:13px; color:var(--muted); margin-bottom:7px; font-weight:700; }
.field input, .field textarea{
  width:100%; padding:11px 13px; border:1.5px solid #ecdfd2; border-radius:11px;
  font-size:14px; outline:none; font-family:inherit; resize:vertical; color:var(--ink);
}
.field input:focus, .field textarea:focus{ border-color:var(--orange); }
.cat-picker{ display:flex; flex-wrap:wrap; gap:8px; }
.cat-opt{
  border:1.5px solid #ecdfd2; background:#fff; color:#7a6a5d; font-family:inherit;
  padding:7px 12px; border-radius:12px; font-size:12.5px; font-weight:700; cursor:pointer; transition:.2s;
}
.cat-opt:hover{ border-color:var(--orange); color:var(--tomato); }
.cat-opt.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }
.emoji-picker{ display:flex; flex-wrap:wrap; gap:7px; }
.emoji-opt{
  width:38px; height:38px; border:1.5px solid #ecdfd2; background:#fff; border-radius:11px;
  font-size:19px; line-height:1; cursor:pointer; transition:.2s;
}
.emoji-opt:hover{ border-color:var(--orange); transform:translateY(-2px); }
.emoji-opt.on{ border-color:transparent; background:linear-gradient(140deg,#ffe7d4,#ffcda8);
  box-shadow:0 6px 14px rgba(255,120,60,.25); }
.msg{ color:var(--err); font-size:12.5px; min-height:16px; margin-bottom:8px; }
.actions{ display:flex; gap:10px; }
.actions .btn{ flex:1; padding:12px; border:0; border-radius:12px; font-weight:700; color:#fff;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); cursor:pointer; font-family:inherit; }
.actions .ghost{ flex:1; padding:12px; border:1.5px solid #ecdfd2; border-radius:12px;
  background:#fff; cursor:pointer; font-weight:700; color:var(--muted); font-family:inherit; }
</style>
