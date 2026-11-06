<script setup>
import { ref, onMounted, computed, watch, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { authUser, logout } from '../composables/useAuth.js'
import { useReviews } from '../composables/useReviews.js'
import { useOrder } from '../composables/useOrder.js'
import { useFavorites } from '../composables/useFavorites.js'
import { useToast } from '../composables/useToast.js'
import { CAT_NAMES, catIcon, catBg, catAccent, catSoft } from '../data/categories.js'

const route = useRoute()
const router = useRouter()
const { toast } = useToast()
const { allReviews, avgRating, count: reviewCount } = useReviews()
const { openOrder } = useOrder()
const { isFav, toggle } = useFavorites()

const posts = ref([])
const loading = ref(false)
const sortBy = ref('new') // new | hot | rating
const activeCat = ref('全部')
const keyword = ref('')
const liked = ref(new Set())

// 分页：每页 12 道，点击页码 / 上一页 / 下一页切换（不依赖滚动加载）
const PAGE_SIZE = 12
const page = ref(1)

// 商圈兜底：后端未返回 district 时按 id 派生
const DISTRICT_FB = { 1:'老城区',2:'大学城',3:'万象城',4:'三里屯',5:'科技园',6:'五道口',7:'大学城',8:'三里屯',9:'南锣鼓巷',10:'五道口',11:'滨江道',12:'老城区' }
function postDistrict(p) { return p.district || DISTRICT_FB[p.id] || '其他' }

// 热门搜索词（可点击回填 + 选中高亮）
const hotWords = ['拉面', '寿司', '炸鸡', '抹茶', '拿铁', '火锅', '轻食', '烧烤']
const EMOJI_PICKS = ['🍜', '🍣', '🍔', '🥗', '🍰', '☕', '🍢', '🍲', '🍱', '🥟', '🍡', '🍟']
// 右侧图标墙（无白底方框，散落排布）
const HERO_ICONS = [
  { e: '🍜', x: 6, y: 8, s: 46, r: -8 }, { e: '🍣', x: 62, y: 4, s: 38, r: 10 },
  { e: '🍔', x: 30, y: 30, s: 52, r: 6 }, { e: '🥗', x: 78, y: 34, s: 40, r: -12 },
  { e: '🍰', x: 14, y: 56, s: 36, r: 9 }, { e: '☕', x: 50, y: 60, s: 44, r: -6 },
  { e: '🍢', x: 84, y: 66, s: 38, r: 12 }, { e: '🍲', x: 40, y: 12, s: 40, r: 4 }
]

// 店铺名：优先用后端 shop 表返回的真实店铺名（店家改名后自动同步），缺失时用历史兜底
const SHOP_POOL = ['巷口小馆', '老地方食堂', '街角食光', '私房一味', '深夜食堂', '暖食屋', '半日闲', '食光小铺', '鲜物记', '好味来', '慢炖锅', '一味居']
function shopName(p) { return p.shopName || SHOP_POOL[(Number(p.id) || 1) % SHOP_POOL.length] }
function distance(p) { return (0.4 + ((Number(p.id) * 37) % 95) / 10).toFixed(1) }
function isNew(p) {
  const t = new Date(p.createdAt).getTime()
  if (!Number.isFinite(t)) return false
  return Date.now() - t < 45 * 86400000
}
function isRecommended(p) { return !!p.featured }

// 排序 + 分类 + 关键词
const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  const list = posts.value.filter(p => {
    if (activeCat.value !== '全部' && p.category !== activeCat.value) return false
    if (!kw) return true
    return (
      (p.title || '').toLowerCase().includes(kw) ||
      (p.content || '').toLowerCase().includes(kw) ||
      (p.author || '').toLowerCase().includes(kw) ||
      (p.shopName || '').toLowerCase().includes(kw) ||
      (p.category || '').toLowerCase().includes(kw)
    )
  })
  const arr = [...list]
  if (sortBy.value === 'hot') {
    arr.sort((a, b) => (b.favoriteCount || 0) - (a.favoriteCount || 0) || (b.reviewCount || 0) - (a.reviewCount || 0) || b.id - a.id)
  } else if (sortBy.value === 'rating') {
    arr.sort((a, b) => (b.rating || 0) - (a.rating || 0) || (b.reviewCount || 0) - (a.reviewCount || 0))
  } else {
    arr.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt) || b.id - a.id)
  }
  return arr
})

// 分页切片：当前页 12 条
const totalPages = computed(() => Math.max(1, Math.ceil(filtered.value.length / PAGE_SIZE)))
const pagedPosts = computed(() => {
  const start = (page.value - 1) * PAGE_SIZE
  return filtered.value.slice(start, start + PAGE_SIZE)
})

// 页码列表：页数多时折叠为 1 … 4 5 6 … 20
const pageList = computed(() => {
  const tp = totalPages.value
  const cur = page.value
  const out = []
  if (tp <= 7) {
    for (let i = 1; i <= tp; i++) out.push(i)
    return out
  }
  out.push(1)
  const from = Math.max(2, cur - 1)
  const to = Math.min(tp - 1, cur + 1)
  if (from > 2) out.push('...')
  for (let i = from; i <= to; i++) out.push(i)
  if (to < tp - 1) out.push('...')
  out.push(tp)
  return out
})

// 搜索 / 分类 / 排序变化时回到第 1 页
watch([keyword, activeCat, sortBy], () => { page.value = 1 })

// 翻页：切页后平滑滚回列表顶部
function goPage(n) {
  const p = Math.min(Math.max(1, n), totalPages.value)
  if (p === page.value) return
  page.value = p
  nextTick(() => {
    const el = document.querySelector('.result-line') || document.querySelector('.grid')
    if (el) window.scrollTo({ top: el.getBoundingClientRect().top + window.scrollY - 96, behavior: 'smooth' })
  })
}

function pickHot(w) { keyword.value = keyword.value === w ? '' : w }
function clearCat() { activeCat.value = '全部' }

// 搜索高亮
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

// 卡片交互
function openPost(id) { router.push(`/post/${id}`) }
// 点击作者昵称 → 发起私信
function openChat(name) {
  if (!name || name === authUser.value) return
  router.push(`/chat?peer=${encodeURIComponent(name)}`)
}
function onOrder(p) { openOrder(p) }
function onFav(id) { toggle(id) }
function onLogout() { logout(); router.push('/login') }
function isLiked(id) { return liked.value.has(Number(id)) }
function onLike(p) {
  const id = Number(p.id)
  if (liked.value.has(id)) { liked.value.delete(id); toast('已取消点赞', 'info') }
  else { liked.value.add(id); toast('已点赞 ❤️', 'success') }
  liked.value = new Set(liked.value)
}
function likeCount(p) { return 20 + (Number(p.id) * 13 % 80) + (isLiked(p.id) ? 1 : 0) }
function fmtPrice(p) { return p.price == null ? '—' : '¥' + p.price }

// 发布
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
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${localStorage.getItem('food_token')}` },
      body: JSON.stringify(form.value)
    })
    const data = await r.json().catch(() => ({}))
    if (!r.ok) { formMsg.value = data.message || '发布失败'; return }
    showForm.value = false
    form.value = { title: '', category: '面食控', content: '', emoji: '🍜' }
    await loadPosts()
  } catch { formMsg.value = '网络错误' }
}

// 今日精选
const featured = computed(() => {
  const rated = [...posts.value].filter(p => reviewCount(p.id) > 0)
  const pool = rated.length >= 3 ? rated : [...posts.value]
  return pool.sort((a, b) => avgRating(b.id) - avgRating(a.id) || reviewCount(b.id) - reviewCount(a.id) || b.id - a.id).slice(0, 3)
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

// 热门点评
const hotReviews = computed(() => {
  const list = allReviews().sort((a, b) => b.at - a.at).slice(0, 6)
  return list.map(r => {
    const p = posts.value.find(x => x.id === r.postId)
    return p ? { ...r, title: p.title, emoji: p.emoji, category: p.category } : null
  }).filter(Boolean)
})
function starStr(n) {
  const f = Math.round(n)
  return '★'.repeat(f) + '☆'.repeat(5 - f)
}
const firstChar = s => (s || '?').trim().charAt(0).toUpperCase()

onMounted(async () => {
  await loadPosts()
  const c = route.query.cat
  if (typeof c === 'string' && CAT_NAMES.includes(c)) activeCat.value = c
})
</script>

<template>
  <div class="home">
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>

    <!-- ===== Banner ===== -->
    <section class="hero">
      <div class="hero-mask" aria-hidden="true"></div>
      <div class="hero-inner">
        <span class="hero-badge">🎉 今日上新 · 发现城市里的好味道</span>
        <h1>发现城市里的<br />每一口好味道</h1>
        <p class="hero-sub" v-if="authUser">Hi，{{ authUser }} 👋 今天想吃点什么？</p>
        <p class="hero-sub" v-else>记录 · 分享 · 收藏你的私藏美食地图</p>

        <div class="searchbar">
          <span class="ic">🔍</span>
          <input v-model="keyword" placeholder="搜索美食、店铺或口味…" @keyup.enter="() => {}" />
          <button v-if="keyword" class="clear" type="button" @click="keyword = ''" aria-label="清空">✕</button>
          <button class="go" type="button" @click="() => {}">搜索</button>
        </div>

        <div class="hotwords">
          <span class="hw-label">大家都在搜</span>
          <button v-for="w in hotWords" :key="w" type="button" :class="{ on: keyword === w }" @click="pickHot(w)">{{ w }}</button>
        </div>
      </div>
      <div class="hero-art" aria-hidden="true">
        <span
          v-for="(it, i) in HERO_ICONS"
          :key="i"
          class="hicon"
          :style="{ left: it.x + '%', top: it.y + '%', fontSize: it.s + 'px', '--rot': it.r + 'deg' }"
        >{{ it.e }}</span>
      </div>
    </section>

    <!-- 独立美食分类筛选行（主题色） -->
    <div class="catbar">
      <button class="cat-all" :class="{ on: activeCat === '全部' }" @click="clearCat">全部</button>
      <button
        v-for="c in CAT_NAMES"
        :key="c"
        class="cat-chip"
        :class="{ on: activeCat === c }"
        :style="{ '--ac': catAccent(c), '--sf': catSoft(c) }"
        @click="activeCat = c"
      >{{ catIcon(c) }} {{ c }}</button>
    </div>

    <div class="result-line" v-if="!loading">
      <h2>{{ activeCat === '全部' ? '全部好味道' : activeCat }}
        <em>共 {{ filtered.length }} 道</em>
      </h2>
      <span v-if="keyword.trim()" class="tb-kw">关键词「{{ keyword.trim() }}」</span>
    </div>

    <!-- 骨架屏 -->
    <div v-if="loading" class="grid">
      <div v-for="n in 6" :key="'sk' + n" class="sk-card">
        <div class="sk-cover"></div>
        <div class="sk-line w80"></div>
        <div class="sk-line w60"></div>
      </div>
    </div>

    <div v-else-if="!filtered.length" class="empty">
      <div class="empty-illu" aria-hidden="true">
        <span class="e-plate"></span><span class="e-emoji">🍽️</span><span class="e-line"></span>
      </div>
      <p class="empty-title">这里还空空如也</p>
      <p class="hint">换个关键词或商圈试试，或点击右下角分享你的私藏好味道～</p>
      <button class="empty-btn" type="button" @click="showForm = true">＋ 发布一道美食</button>
    </div>

    <!-- ===== 美食卡片 ===== -->
    <div v-else class="grid">
      <article
        v-for="(p, index) in pagedPosts"
        :key="p.id"
        class="card"
        :style="{ '--ac': catAccent(p.category), '--i': index }"
        @click="openPost(p.id)"
      >
        <div class="card-cover" :style="{ background: catBg(p.category) }">
          <span class="cover-emoji">{{ p.emoji }}</span>
          <span class="cover-cat">{{ catIcon(p.category) }} {{ p.category }}</span>
          <div class="cover-tags">
            <span v-if="isNew(p)" class="ctag new">新店</span>
            <span v-if="isRecommended(p)" class="ctag rec">推荐</span>
          </div>
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

          <div class="card-meta">
            <span class="rating">
              <span class="stars" :class="{ empty: !avgRating(p.id) }">{{ starStr(avgRating(p.id) || 0) }}</span>
              <b>{{ avgRating(p.id) ? avgRating(p.id).toFixed(1) : '暂无' }}</b>
            </span>
            <span class="dot">·</span>
            <span class="shop" :title="p.shopOwner ? `私信店铺 @${p.shopOwner}` : '店铺'" @click.stop="openChat(p.shopOwner || p.author)">🏠 {{ shopName(p) }}</span>
            <span class="dist">📍 {{ postDistrict(p) }} {{ distance(p) }}km</span>
          </div>

          <p class="excerpt" v-html="hl(p.content)"></p>

          <div class="card-foot">
            <span class="avatar">{{ firstChar(p.author) }}</span>
            <span class="author chat-link" :class="{ self: p.author === authUser }" @click.stop="openChat(p.author)">@{{ p.author }}</span>
            <span class="price">人均 {{ fmtPrice(p) }}</span>
            <button
              class="like-btn"
              :class="{ on: isLiked(p.id) }"
              type="button"
              :title="isLiked(p.id) ? '取消点赞' : '点赞'"
              @click.stop="onLike(p)"
            >{{ isLiked(p.id) ? '❤️' : '🤍' }} <i>{{ likeCount(p) }}</i></button>
          </div>
        </div>
      </article>
    </div>

    <!-- 分页：上一页 / 页码 / 下一页 -->
    <nav v-if="!loading && filtered.length" class="pager" aria-label="分页导航">
      <button class="pg-btn" type="button" :disabled="page === 1" @click="goPage(page - 1)">← 上一页</button>
      <div class="pg-nums">
        <template v-for="(it, i) in pageList" :key="'pg' + i">
          <span v-if="it === '...'" class="pg-dots">…</span>
          <button v-else class="pg-num" type="button" :class="{ on: it === page }" @click="goPage(it)">{{ it }}</button>
        </template>
      </div>
      <button class="pg-btn" type="button" :disabled="page === totalPages" @click="goPage(page + 1)">下一页 →</button>
      <span class="pg-info">第 {{ page }} / {{ totalPages }} 页 · 共 {{ filtered.length }} 道</span>
    </nav>

    <!-- 今日精选 -->
    <section class="featured" v-if="!loading && featured.length">
      <div class="sec-head">
        <h2>🔥 今日精选</h2>
        <span class="sec-sub">编辑部私藏的 {{ featured.length }} 道，闭眼点不踩雷</span>
      </div>
      <div class="feat-list">
        <article v-for="p in featured" :key="'f' + p.id" class="feat-card" @click="openPost(p.id)">
          <div class="feat-emoji" :style="{ background: catBg(p.category) }">{{ p.emoji }}</div>
          <div class="feat-body">
            <span class="feat-cat" :style="{ color: catAccent(p.category), background: catSoft(p.category) }">{{ p.category }}</span>
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

    <!-- 热门点评 -->
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

    <!-- 平台数据概览 -->
    <section class="stats-band" v-if="!loading">
      <div class="stat"><b>{{ stats.posts }}</b><span>篇美食笔记</span></div>
      <div class="stat"><b>{{ stats.authors }}</b><span>位吃货分享者</span></div>
      <div class="stat"><b>{{ stats.reviews }}</b><span>条真实点评</span></div>
      <div class="stat"><b>{{ stats.cats }}</b><span>大美食分类</span></div>
    </section>

    <!-- 发布入口 -->
    <button class="fab" type="button" @click="showForm = true" title="发布美食笔记">
      <span class="fab-ic">＋</span>
      <span class="fab-tip">发布美食笔记</span>
    </button>

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
            <button v-for="c in CAT_NAMES" :key="c" type="button" class="cat-opt"
              :class="{ on: form.category === c }" @click="form.category = c">{{ catIcon(c) }} {{ c }}</button>
          </div>
        </div>
        <div class="field">
          <label>选个图标</label>
          <div class="emoji-picker">
            <button v-for="e in EMOJI_PICKS" :key="e" type="button" class="emoji-opt"
              :class="{ on: form.emoji === e }" @click="form.emoji = e">{{ e }}</button>
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
.home{ position:relative; max-width:1100px; margin:0 auto; padding:22px 22px 110px; z-index:1; }

.bg-orbs{ position:absolute; inset:0; pointer-events:none; z-index:0; }
.bg-orbs span{ position:absolute; font-size:40px; opacity:.15; animation:orb 9s ease-in-out infinite; filter:blur(.3px); }
.o1{ left:4%; top:12%; } .o2{ left:82%; top:10%; animation-delay:.8s; }
.o3{ left:10%; top:70%; animation-delay:1.6s; } .o4{ left:88%; top:66%; animation-delay:2.4s; }
.o5{ left:44%; top:6%; animation-delay:3.2s; } .o6{ left:62%; top:82%; animation-delay:1.1s; }
.o7{ left:26%; top:40%; animation-delay:2.7s; font-size:54px; } .o8{ left:72%; top:44%; animation-delay:3.6s; }
@keyframes orb{ 0%,100%{ transform:translateY(0) rotate(-6deg); } 50%{ transform:translateY(-22px) rotate(8deg); } }

/* ===== Banner ===== */
.hero{ position:relative; overflow:hidden; z-index:1; border-radius:26px; padding:38px 36px 30px; color:#fff;
  box-shadow:var(--ring); display:flex; align-items:center; gap:24px; min-height:230px; }
.hero-mask{ position:absolute; inset:0; background:linear-gradient(135deg,rgba(255,154,82,.92) 0%,rgba(255,95,61,.9) 48%,rgba(224,51,60,.92) 100%); }
.hero-inner{ position:relative; z-index:2; flex:1; min-width:0; }
.hero-badge{ display:inline-block; font-size:12px; font-weight:700; background:rgba(255,255,255,.2);
  border:1px solid rgba(255,255,255,.32); padding:5px 12px; border-radius:999px; margin-bottom:14px; }
.hero h1{ font-size:34px; line-height:1.22; font-weight:800; letter-spacing:.5px; text-shadow:0 2px 10px rgba(120,30,10,.25); }
.hero-sub{ margin-top:10px; font-size:14.5px; opacity:.95; }
/* 搜索栏：层次感 */
.searchbar{ display:flex; align-items:center; gap:10px; margin-top:22px; max-width:560px;
  background:#fff; border-radius:999px; padding:7px 7px 7px 18px; box-shadow:0 14px 30px rgba(140,30,10,.26), inset 0 2px 6px rgba(0,0,0,.06); }
.searchbar .ic{ font-size:18px; opacity:.5; }
.searchbar input{ flex:1; min-width:0; border:0; outline:none; background:transparent; font-size:15.5px; color:var(--ink); font-family:inherit; padding:10px 0; }
.searchbar .clear{ border:0; background:#f0e6db; color:var(--muted); cursor:pointer; width:26px; height:26px; border-radius:50%; font-size:12px; line-height:1; flex-shrink:0; }
.searchbar .clear:hover{ background:#e7ddd2; }
.searchbar .go{ flex-shrink:0; border:0; cursor:pointer; font-weight:800; font-size:15px; color:#fff; padding:12px 26px; border-radius:999px;
  background:linear-gradient(120deg,#ff7a3d,#e23b3b); box-shadow:0 8px 18px rgba(226,59,59,.38); transition:.2s; }
.searchbar .go:hover{ filter:brightness(1.1); transform:translateY(-1px); }
/* 热门标签 */
.hotwords{ display:flex; align-items:center; gap:8px; flex-wrap:wrap; margin-top:15px; position:relative; z-index:2; }
.hw-label{ font-size:12px; opacity:.8; }
.hotwords button{ border:1px solid rgba(255,255,255,.4); background:rgba(255,255,255,.14); color:#fff; font-size:12.5px;
  padding:5px 12px; border-radius:999px; cursor:pointer; transition:.2s; font-family:inherit; }
.hotwords button:hover{ background:rgba(255,255,255,.32); }
.hotwords button.on{ background:#fff; color:var(--tomato); border-color:#fff; font-weight:800; }
/* 右侧散落图标墙（无白底方框） */
.hero-art{ position:relative; flex-shrink:0; width:230px; height:200px; }
.hicon{ position:absolute; transform:rotate(var(--rot)); filter:drop-shadow(0 6px 10px rgba(120,40,20,.35)); cursor:default;
  transition:transform .3s ease, filter .3s ease; }
.hicon:hover{ transform:rotate(0deg) scale(1.25); filter:drop-shadow(0 10px 16px rgba(120,40,20,.5)) saturate(1.3); }

/* ===== 分类筛选行 ===== *//* 独立分类筛选行 */
.catbar{ display:flex; align-items:center; gap:8px; flex-wrap:wrap; margin-top:20px; }
.cat-all{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted); font-size:12.5px; font-weight:700; padding:6px 14px;
  border-radius:999px; cursor:pointer; transition:.2s; font-family:inherit; white-space:nowrap; }
.cat-all:hover{ border-color:var(--orange); color:var(--tomato); }
.cat-all.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); color:#fff; border-color:transparent; box-shadow:0 6px 14px rgba(255,90,60,.26); }
.cat-chip{ border:1.5px solid var(--sf); background:var(--sf); color:var(--ac); font-size:12.5px; font-weight:700; padding:6px 12px;
  border-radius:999px; cursor:pointer; transition:.22s; font-family:inherit; white-space:nowrap; }
.cat-chip:hover{ transform:translateY(-2px); box-shadow:0 6px 14px rgba(0,0,0,.1); }
.cat-chip.on{ background:var(--ac); border-color:transparent; color:#fff; box-shadow:0 6px 14px rgba(0,0,0,.18); }

.result-line{ display:flex; align-items:baseline; gap:10px; flex-wrap:wrap; margin:18px 2px 12px; }
.result-line h2{ font-size:20px; font-weight:800; color:var(--ink); }
.result-line h2 em{ font-style:normal; font-size:13px; font-weight:600; color:var(--muted); margin-left:6px; }
.tb-kw{ font-size:12.5px; color:var(--tomato); background:#fff0ea; padding:3px 10px; border-radius:999px; }

/* ===== 卡片网格 ===== */
.grid{ position:relative; z-index:1; display:grid; grid-template-columns:repeat(3,1fr); gap:18px; }
.card{ background:#fff; border-radius:20px; overflow:hidden; cursor:pointer; border:1.5px solid #f6ebe0;
  box-shadow:0 10px 24px rgba(255,120,80,.07); transition:transform .24s, box-shadow .24s, border-color .24s; display:flex; flex-direction:column;
  animation:cardIn .45s backwards; animation-delay:calc(var(--i,0) * 45ms); }
@keyframes cardIn{ from{ opacity:0; transform:translateY(14px); } to{ opacity:1; transform:translateY(0); } }
.card:hover{ transform:translateY(-6px); box-shadow:0 22px 42px rgba(255,90,60,.2); border-color:#ffd9bf; }
.card-cover{ position:relative; height:160px; display:flex; align-items:center; justify-content:center; overflow:hidden; }
.card-cover::after{ content:""; position:absolute; inset:0; background:linear-gradient(180deg,rgba(0,0,0,0) 40%,rgba(0,0,0,.28)); }
.cover-emoji{ position:relative; z-index:2; font-size:64px; line-height:1; filter:drop-shadow(0 10px 14px rgba(160,90,50,.24)); transition:transform .3s; }
.card:hover .cover-emoji{ transform:scale(1.16) rotate(-5deg); }
.cover-cat{ position:absolute; z-index:3; left:12px; bottom:11px; font-size:11px; font-weight:700; color:#7e5a3e;
  background:rgba(255,255,255,.85); padding:3px 10px; border-radius:9px; backdrop-filter:blur(3px); }
.cover-tags{ position:absolute; z-index:3; left:12px; top:11px; display:flex; gap:6px; }
.ctag{ font-size:11px; font-weight:800; padding:3px 9px; border-radius:999px; color:#fff; box-shadow:0 3px 8px rgba(0,0,0,.18); }
.ctag.new{ background:linear-gradient(120deg,#3aa0ff,#2e7fd6); }
.ctag.rec{ background:linear-gradient(120deg,#ff7a3d,#e23b3b); }
.fav-btn{ position:absolute; z-index:3; top:11px; right:11px; width:32px; height:32px; border-radius:50%; border:0; cursor:pointer;
  font-size:15px; line-height:1; color:#bda995; background:rgba(255,255,255,.85); transition:transform .2s, color .2s, background .2s; }
.fav-btn:hover{ transform:scale(1.12); color:var(--orange); }
.fav-btn.on{ color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 6px 14px rgba(255,90,60,.35); }

.card-body{ padding:14px 16px 15px; display:flex; flex-direction:column; flex:1; }
.card-body h3{ font-size:16px; line-height:1.4; margin-bottom:8px; color:var(--ink); font-weight:800; }
.card-meta{ display:flex; align-items:center; gap:7px; font-size:12.5px; margin-bottom:8px; flex-wrap:wrap; }
.card-meta .rating{ display:flex; align-items:center; gap:5px; }
.card-meta .stars{ color:#f5a623; letter-spacing:.5px; }
.card-meta .stars.empty{ color:#d6cabd; }
.card-meta .rating b{ color:var(--tomato); font-weight:800; }
.card-meta .dot{ color:#d9cabb; }
.card-meta .shop{ color:var(--muted); font-weight:600; cursor:pointer; transition:color .2s; }
.card-meta .shop:hover{ color:var(--tomato); }
.card-meta .dist{ color:var(--muted); font-weight:600; }
.excerpt{ font-size:12.8px; color:#9b8c7e; line-height:1.6; flex:1; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.card-foot{ display:flex; align-items:center; gap:8px; margin-top:12px; font-size:12px; }
.avatar{ width:24px; height:24px; border-radius:50%; flex-shrink:0; display:flex; align-items:center; justify-content:center; font-size:11px; font-weight:800; color:#8a4b22; background:linear-gradient(140deg,#ffe0c8,#ffbe90); }
.author{ white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:64px; color:var(--muted); }
.author.chat-link{ cursor:pointer; border-bottom:1px dashed transparent; transition:.2s; flex-shrink:0; max-width:110px; }
.author.chat-link:hover{ color:var(--tomato); border-bottom-color:var(--tomato); }
.author.chat-link.self{ cursor:default; }
.author.chat-link.self:hover{ color:var(--muted); border-bottom-color:transparent; }
.price{ color:var(--tomato); font-weight:800; white-space:nowrap; }
.like-btn{ margin-left:auto; border:1.5px solid #f0e2d4; background:#fff; color:#c98b6a; padding:6px 11px; border-radius:11px;
  font-size:12.5px; font-weight:700; cursor:pointer; transition:.18s; font-family:inherit; display:flex; align-items:center; gap:4px; }
.like-btn:hover{ border-color:var(--orange); color:var(--tomato); transform:scale(1.05); }
.like-btn.on{ border-color:transparent; color:#fff; background:linear-gradient(120deg,#ff7a8f,#e23b6b); box-shadow:0 6px 14px rgba(226,59,107,.3); }
.like-btn.on i{ font-style:normal; }
.like-btn.on{ animation:pop .3s ease; }
@keyframes pop{ 0%{ transform:scale(1); } 40%{ transform:scale(1.35); } 100%{ transform:scale(1); } }

/* 分页控件 */
.pager{
  display:flex; align-items:center; justify-content:center; gap:10px; flex-wrap:wrap;
  padding:26px 0 6px;
}
.pg-btn{
  border:1.5px solid #ecdfd2; background:#fff; color:var(--ink);
  padding:9px 16px; border-radius:11px; font-size:13.5px; font-weight:700;
  cursor:pointer; transition:.2s; white-space:nowrap;
}
.pg-btn:hover:not(:disabled){ border-color:var(--orange); color:var(--orange); background:#fffaf4; }
.pg-btn:disabled{ opacity:.45; cursor:not-allowed; }
.pg-nums{ display:flex; align-items:center; gap:6px; }
.pg-num{
  min-width:36px; height:36px; padding:0 8px; border-radius:10px; cursor:pointer;
  border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  font-size:13.5px; font-weight:700; transition:.2s;
}
.pg-num:hover{ border-color:var(--orange); color:var(--orange); }
.pg-num.on{
  background:linear-gradient(120deg,var(--orange),var(--tomato)); color:#fff; border-color:transparent;
  box-shadow:0 6px 14px rgba(255,90,60,.28);
}
.pg-dots{ color:#c4b3a4; padding:0 2px; }
.pg-info{ width:100%; text-align:center; color:var(--muted); font-size:12.5px; margin-top:2px; }

/* 骨架屏 */
.sk-card{ background:#fff; border-radius:18px; padding:0 0 16px; overflow:hidden; border:1.5px solid #f6ebe0; }
.sk-cover{ height:160px; background:#f6eee6; }
.sk-line{ height:11px; border-radius:6px; margin:12px 15px 0; background:#f4ece4; animation:shimmer 1.4s ease-in-out infinite; }
.sk-line.w80{ width:80%; } .sk-line.w60{ width:60%; }
@keyframes shimmer{ 0%,100%{ opacity:1; } 50%{ opacity:.45; } }

/* 空状态 */
.empty{ position:relative; z-index:1; text-align:center; padding:48px 20px 16px; }
.empty-illu{ position:relative; width:120px; height:120px; margin:0 auto 8px; }
.e-plate{ position:absolute; left:50%; top:50%; width:104px; height:104px; transform:translate(-50%,-50%); border-radius:50%;
  background:linear-gradient(140deg,#fff,#ffe9d6); box-shadow:0 14px 30px rgba(255,120,80,.16); }
.e-emoji{ position:absolute; left:50%; top:50%; transform:translate(-50%,-50%); font-size:52px; }
.e-line{ position:absolute; left:50%; bottom:-6px; width:70px; height:8px; transform:translateX(-50%); border-radius:50%; background:rgba(255,120,80,.18); }
.empty-title{ font-size:17px; font-weight:800; color:var(--ink); margin:12px 0 6px; }
.hint{ position:relative; z-index:1; color:var(--muted); text-align:center; }
.empty-btn{ margin-top:16px; border:0; border-radius:12px; padding:11px 20px; font-weight:700; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 8px 18px rgba(255,90,60,.3); }
.empty-btn:hover{ filter:brightness(1.04); }

/* 关键词高亮 */
:deep(.hl){ background:linear-gradient(120deg,#ffe08a,#ffd166); color:#5a3b00; border-radius:4px; padding:0 2px; font-weight:700; }

/* 区块标题 */
.sec-head{ display:flex; align-items:baseline; gap:12px; flex-wrap:wrap; margin:34px 0 14px; }
.sec-head h2{ font-size:20px; font-weight:800; color:var(--ink); }
.sec-sub{ font-size:12.5px; color:var(--muted); }
.feat-list{ display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.feat-card{ display:flex; gap:13px; background:#fff; border-radius:18px; padding:15px; cursor:pointer; border:1.5px solid #f6ebe0;
  box-shadow:0 10px 24px rgba(255,120,80,.08); transition:transform .2s, box-shadow .2s; animation:cardIn .45s backwards; }
.feat-card:hover{ transform:translateY(-4px); box-shadow:0 16px 32px rgba(255,90,60,.18); border-color:#ffd9bf; }
.feat-emoji{ flex-shrink:0; width:58px; height:58px; border-radius:16px; display:flex; align-items:center; justify-content:center; font-size:30px; box-shadow:inset 0 0 0 1px rgba(255,255,255,.7); }
.feat-body{ min-width:0; }
.feat-cat{ font-size:11px; font-weight:700; padding:2px 9px; border-radius:9px; }
.feat-body h3{ font-size:15px; margin:7px 0 5px; line-height:1.35; color:var(--ink); }
.feat-excerpt{ font-size:12.5px; color:#9b8c7e; line-height:1.55; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.feat-foot{ display:flex; align-items:center; gap:7px; margin-top:9px; font-size:12px; }
.feat-foot .author{ color:#bba; margin-left:auto; }
.stars{ color:#f5a623; letter-spacing:.5px; }
.score{ color:var(--tomato); font-weight:800; }

.feed-list{ display:grid; grid-template-columns:repeat(2,1fr); gap:14px; }
.feed-card{ display:flex; gap:12px; background:#fff; border-radius:16px; padding:14px; cursor:pointer; border:1.5px solid #f6ebe0;
  box-shadow:0 8px 20px rgba(255,120,80,.07); transition:transform .2s, box-shadow .2s, border-color .2s; animation:cardIn .45s backwards; }
.feed-card:hover{ transform:translateY(-3px); box-shadow:0 14px 28px rgba(255,90,60,.16); border-color:#ffd9bf; }
.feed-emoji{ font-size:32px; flex-shrink:0; }
.feed-body{ min-width:0; }
.feed-top{ display:flex; align-items:center; gap:8px; }
.feed-name{ font-size:15px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; color:var(--ink); }
.feed-stars{ font-size:12px; color:#f5a623; flex-shrink:0; }
.feed-comment{ font-size:13px; color:#9b8c7e; line-height:1.6; margin:6px 0; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.feed-by{ font-size:12px; color:#bba; }

.stats-band{ margin-top:36px; display:grid; grid-template-columns:repeat(4,1fr); gap:14px; padding:20px; border-radius:18px;
  background:rgba(255,255,255,.7); border:1.5px solid #f3e7da; box-shadow:0 10px 26px rgba(255,90,60,.06); }
.stat{ text-align:center; }
.stat b{ display:block; font-size:26px; font-weight:800; color:var(--tomato); line-height:1.1; }
.stat span{ font-size:12.5px; color:var(--muted); }

/* 发布按钮 + 提示 */
.fab{ position:fixed; right:24px; bottom:24px; z-index:15; width:60px; height:60px; border:0; border-radius:50%; cursor:pointer;
  font-size:27px; color:#fff; line-height:1; background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 12px 26px rgba(255,90,60,.42);
  display:flex; align-items:center; justify-content:center; transition:.2s; }
.fab:hover{ transform:translateY(-3px) scale(1.05); }
.fab-ic{ transition:transform .3s; }
.fab:hover .fab-ic{ transform:rotate(90deg); }
.fab-tip{ position:absolute; right:70px; white-space:nowrap; background:var(--ink); color:#fff; font-size:12.5px; font-weight:600;
  padding:7px 12px; border-radius:10px; opacity:0; transform:translateX(8px); transition:.25s; pointer-events:none; }
.fab-tip::after{ content:""; position:absolute; right:-5px; top:50%; transform:translateY(-50%) rotate(45deg); width:10px; height:10px; background:var(--ink); }
.fab:hover .fab-tip{ opacity:1; transform:translateX(0); }

/* 发布弹窗 */
.modal{ position:fixed; inset:0; background:rgba(40,20,10,.45); display:flex; align-items:center; justify-content:center; padding:20px; z-index:20; animation:mfade .2s ease; }
@keyframes mfade{ from{ opacity:0; } to{ opacity:1; } }
.sheet{ background:#fff; border-radius:20px; padding:24px; width:min(460px,100%); max-height:90vh; overflow:auto; box-shadow:0 24px 60px rgba(0,0,0,.28); animation:mpop .26s cubic-bezier(.2,.9,.3,1.2); }
@keyframes mpop{ from{ opacity:0; transform:translateY(16px) scale(.97); } to{ opacity:1; transform:translateY(0) scale(1); } }
.sheet h3{ font-size:19px; font-weight:800; color:var(--ink); }
.sheet-sub{ font-size:12.5px; color:var(--muted); margin:5px 0 16px; }
.field{ margin-bottom:14px; }
.field label{ display:block; font-size:13px; color:var(--muted); margin-bottom:7px; font-weight:700; }
.field input, .field textarea{ width:100%; padding:11px 13px; border:1.5px solid #ecdfd2; border-radius:11px; font-size:14px; outline:none; font-family:inherit; resize:vertical; color:var(--ink); box-sizing:border-box; }
.field input:focus, .field textarea:focus{ border-color:var(--orange); }
.cat-picker{ display:flex; flex-wrap:wrap; gap:8px; }
.cat-opt{ border:1.5px solid #ecdfd2; background:#fff; color:#7a6a5d; font-family:inherit; padding:7px 12px; border-radius:12px; font-size:12.5px; font-weight:700; cursor:pointer; transition:.2s; }
.cat-opt:hover{ border-color:var(--orange); color:var(--tomato); }
.cat-opt.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }
.emoji-picker{ display:flex; flex-wrap:wrap; gap:7px; }
.emoji-opt{ width:38px; height:38px; border:1.5px solid #ecdfd2; background:#fff; border-radius:11px; font-size:19px; line-height:1; cursor:pointer; transition:.2s; }
.emoji-opt:hover{ border-color:var(--orange); transform:translateY(-2px); }
.emoji-opt.on{ border-color:transparent; background:linear-gradient(140deg,#ffe7d4,#ffcda8); box-shadow:0 6px 14px rgba(255,120,60,.25); }
.msg{ color:var(--err); font-size:12.5px; min-height:16px; margin-bottom:8px; }
.actions{ display:flex; gap:10px; }
.actions .btn{ flex:1; padding:12px; border:0; border-radius:12px; font-weight:700; color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato)); cursor:pointer; font-family:inherit; }
.actions .ghost{ flex:1; padding:12px; border:1.5px solid #ecdfd2; border-radius:12px; background:#fff; cursor:pointer; font-weight:700; color:var(--muted); font-family:inherit; }

@media (max-width:900px){ .grid{ grid-template-columns:repeat(2,1fr); } .feat-list{ grid-template-columns:1fr; } }
@media (max-width:760px){
  .hero{ flex-direction:column; align-items:stretch; padding:30px 22px 24px; }
  .hero-art{ display:none; }
  .hero h1{ font-size:28px; }
  .searchbar{ max-width:none; }
  .stats-band{ grid-template-columns:repeat(2,1fr); row-gap:16px; }
  .feed-list{ grid-template-columns:1fr; }
}
@media (max-width:520px){
  .home{ padding:16px 14px 100px; }
  .grid{ grid-template-columns:1fr; }
  .catbar{ gap:6px; }
}
</style>
