<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useFavorites } from '../composables/useFavorites.js'
import { useReviews } from '../composables/useReviews.js'

const router = useRouter()
const { ids: favIds } = useFavorites()
const { avgRating, count: reviewCount } = useReviews()

const posts = ref([])
const tab = ref('hot') // hot | rating | author
const loading = ref(false)

async function loadPosts() {
  loading.value = true
  try {
    const r = await fetch('/api/posts')
    posts.value = await r.json()
  } finally {
    loading.value = false
  }
}

// 人气榜：按评价数 + 是否收藏，纯前端可观测热度
const hotList = computed(() =>
  [...posts.value].map(p => {
    const rev = reviewCount(p.id)
    const fav = favIds.value.has(Number(p.id)) ? 1 : 0
    return { ...p, heat: rev * 10 + fav }
  }).sort((a, b) => b.heat - a.heat).slice(0, 8)
)

// 好评榜：有评价且均分高
const ratingList = computed(() =>
  [...posts.value]
    .map(p => ({ ...p, avg: avgRating(p.id), n: reviewCount(p.id) }))
    .filter(p => p.n > 0)
    .sort((a, b) => b.avg - a.avg || b.n - a.n)
    .slice(0, 8)
)

// 食客榜：按作者聚合发帖数 + 帖子均分
const authorList = computed(() => {
  const map = {}
  for (const p of posts.value) {
    const a = p.author || '匿名'
    if (!map[a]) map[a] = { author: a, posts: 0, sum: 0, cnt: 0 }
    map[a].posts++
    const av = avgRating(p.id)
    if (av) { map[a].sum += av; map[a].cnt++ }
  }
  return Object.values(map)
    .map(m => ({ ...m, avg: m.cnt ? m.sum / m.cnt : 0 }))
    .sort((x, y) => y.posts - x.posts || y.avg - x.avg)
    .slice(0, 8)
})

function openPost(id) { router.push(`/post/${id}`) }
function goProfile() { router.push('/profile') }
function goMap() { router.push('/map') }
function medal(rank) { return ['🥇', '🥈', '🥉'][rank] || (rank + 1) }
function starStr(n) {
  const f = Math.round(n)
  return '★'.repeat(f) + '☆'.repeat(5 - f)
}

onMounted(loadPosts)
</script>

<template>
  <div class="ranking">
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>

    <div class="topbar">
      <button class="back" @click="router.push('/')">← 返回广场</button>
      <div class="top-right">
        <button class="mine" @click="goMap">美食地图</button>
        <button class="mine" @click="goProfile">我的</button>
      </div>
    </div>

    <header class="rhead">
      <h1>🏆 食光排行榜</h1>
      <p>人气、口碑、食客，三榜看尽社区好味道</p>
    </header>

    <nav class="tabs">
      <button :class="{ on: tab === 'hot' }" @click="tab = 'hot'">🔥 人气榜</button>
      <button :class="{ on: tab === 'rating' }" @click="tab = 'rating'">⭐ 好评榜</button>
      <button :class="{ on: tab === 'author' }" @click="tab = 'author'">🍴 食客榜</button>
    </nav>

    <p v-if="loading" class="loader-wrap"><span class="spinner"></span></p>

    <!-- 人气榜 -->
    <ul v-else-if="tab === 'hot'" class="rlist">
      <li v-for="(p, i) in hotList" :key="p.id" class="ritem" @click="openPost(p.id)">
        <span class="rank">{{ medal(i) }}</span>
        <span class="r-emoji">{{ p.emoji }}</span>
        <div class="r-body">
          <div class="r-title">{{ p.title }}</div>
          <div class="r-sub">@{{ p.author }} · {{ p.category }}</div>
        </div>
        <div class="r-metric">
          <span class="r-heat">💬 {{ reviewCount(p.id) }}</span>
          <span v-if="favIds.has(Number(p.id))" class="r-fav">★ 已收藏</span>
        </div>
      </li>
      <li v-if="!hotList.length" class="rempty">还没有数据，去发布或点评第一道美食吧～</li>
    </ul>

    <!-- 好评榜 -->
    <ul v-else-if="tab === 'rating'" class="rlist">
      <li v-for="(p, i) in ratingList" :key="p.id" class="ritem" @click="openPost(p.id)">
        <span class="rank">{{ medal(i) }}</span>
        <span class="r-emoji">{{ p.emoji }}</span>
        <div class="r-body">
          <div class="r-title">{{ p.title }}</div>
          <div class="r-sub">@{{ p.author }} · {{ p.category }}</div>
        </div>
        <div class="r-metric">
          <span class="r-stars">{{ starStr(p.avg) }}</span>
          <span class="r-avg">{{ p.avg.toFixed(1) }}（{{ p.n }}）</span>
        </div>
      </li>
      <li v-if="!ratingList.length" class="rempty">还没有评价，去帖子下抢沙发打个分吧～</li>
    </ul>

    <!-- 食客榜 -->
    <ul v-else class="rlist">
      <li v-for="(m, i) in authorList" :key="m.author" class="ritem author">
        <span class="rank">{{ medal(i) }}</span>
        <span class="r-emoji">🧑‍🍳</span>
        <div class="r-body">
          <div class="r-title">@{{ m.author }}</div>
          <div class="r-sub">发布 {{ m.posts }} 篇 · 均分 {{ m.avg.toFixed(1) }}</div>
        </div>
        <div class="r-metric">
          <span class="r-heat">📝 {{ m.posts }}</span>
        </div>
      </li>
      <li v-if="!authorList.length" class="rempty">还没有食客数据～</li>
    </ul>
  </div>
</template>

<style scoped>
.ranking{ position:relative; max-width:760px; margin:0 auto; padding:24px 24px 60px; z-index:1; }
.bg-orbs{ position:absolute; inset:0; pointer-events:none; z-index:0; }
.bg-orbs span{ position:absolute; font-size:38px; opacity:.12; animation:orb 9s ease-in-out infinite; filter:blur(.3px); }
.o1{ left:3%; top:14%; } .o2{ left:84%; top:12%; animation-delay:.8s; }
.o3{ left:8%; top:72%; animation-delay:1.6s; } .o4{ left:88%; top:68%; animation-delay:2.4s; }
.o5{ left:46%; top:5%; animation-delay:3.2s; } .o6{ left:60%; top:84%; animation-delay:1.1s; }
.o7{ left:24%; top:42%; animation-delay:2.7s; font-size:50px; } .o8{ left:74%; top:46%; animation-delay:3.6s; }
@keyframes orb{ 0%,100%{ transform:translateY(0) rotate(-6deg);} 50%{ transform:translateY(-22px) rotate(8deg);} }

.topbar{ position:relative; z-index:2; display:flex; align-items:center; justify-content:space-between; margin-bottom:18px; }
.back, .mine{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted); padding:8px 14px;
  border-radius:11px; cursor:pointer; font-weight:600; transition:.2s; }
.back:hover, .mine:hover{ border-color:var(--orange); color:var(--tomato); }
.top-right{ display:flex; gap:10px; }

.rhead{ position:relative; z-index:2; margin-bottom:16px; }
.rhead h1{ font-size:26px; font-weight:800; }
.rhead p{ margin-top:6px; color:var(--muted); font-size:14px; }

.tabs{ position:relative; z-index:2; display:flex; gap:8px; margin-bottom:18px; }
.tabs button{ flex:1; border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:10px; border-radius:14px; font-size:14px; font-weight:700; cursor:pointer; transition:.2s; }
.tabs button:hover{ border-color:var(--orange); color:var(--orange); }
.tabs button.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff;
  box-shadow:0 8px 18px rgba(255,90,60,.28); }

.loader-wrap{ position:relative; z-index:2; display:flex; justify-content:center; padding:60px 0; }
.spinner{ width:32px; height:32px; border-radius:50%; border:3px solid #f0e6db; border-top-color:var(--tomato); animation:spin .8s linear infinite; }
@keyframes spin{ to{ transform:rotate(360deg);} }

.rlist{ position:relative; z-index:2; list-style:none; display:flex; flex-direction:column; gap:12px; }
.ritem{ display:flex; align-items:center; gap:14px; background:#fff; border-radius:16px; padding:14px 16px;
  box-shadow:0 8px 20px rgba(0,0,0,.05); cursor:pointer; transition:transform .2s, box-shadow .2s; animation:cardIn .4s backwards; }
@keyframes cardIn{ from{ opacity:0; transform:translateY(12px);} to{ opacity:1; transform:translateY(0);} }
.ritem:hover{ transform:translateY(-3px); box-shadow:0 14px 28px rgba(255,90,60,.16); }
.ritem.author{ cursor:default; }
.ritem.author:hover{ transform:none; box-shadow:0 8px 20px rgba(0,0,0,.05); }
.rank{ font-size:22px; width:34px; text-align:center; font-weight:800; }
.r-emoji{ font-size:30px; }
.r-body{ flex:1; min-width:0; }
.r-title{ font-size:16px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.r-sub{ font-size:12.5px; color:var(--muted); margin-top:3px; }
.r-metric{ text-align:right; display:flex; flex-direction:column; gap:3px; }
.r-heat{ font-size:15px; font-weight:800; color:var(--tomato); }
.r-fav{ font-size:12px; color:var(--orange); font-weight:600; }
.r-stars{ font-size:14px; color:#f5a623; letter-spacing:1px; }
.r-avg{ font-size:12.5px; color:var(--muted); }
.rempty{ position:relative; z-index:2; text-align:center; color:var(--muted); padding:40px 0; }
</style>
