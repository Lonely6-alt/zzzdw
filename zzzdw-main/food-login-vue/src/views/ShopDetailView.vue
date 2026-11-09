<script setup>
// 公开店铺详情：食客视角，只展示已上架的菜品（下架/待审核不出现）
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from '../composables/useToast.js'

const route = useRoute()
const router = useRouter()
const { toast } = useToast()

const shop = ref(null)
const posts = ref([])
const loading = ref(false)
const notFound = ref(false)

async function load() {
  loading.value = true
  try {
    const id = route.params.id
    const detailRes = await fetch(`/api/shops/${id}`)
    if (detailRes.status === 404) { notFound.value = true; return }
    if (!detailRes.ok) throw new Error('店铺加载失败')
    shop.value = await detailRes.json()

    const postRes = await fetch(`/api/shops/${id}/posts`)
    posts.value = postRes.ok ? await postRes.json() : []
  } catch (e) {
    toast(e.message || '店铺加载失败', 'error')
  } finally {
    loading.value = false
  }
}

function openPost(id) { router.push(`/post/${id}`) }
function dateStr(t) {
  if (!t) return '—'
  const d = new Date(t)
  return Number.isFinite(d.getTime())
    ? `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    : '—'
}
function stars(n) {
  const f = Math.round(Number(n) || 0)
  return '★'.repeat(f) + '☆'.repeat(Math.max(0, 5 - f))
}

onMounted(load)
</script>

<template>
  <div class="shop-detail">
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>

    <div class="topbar">
      <button class="back" @click="router.push('/map')">← 返回美食地图</button>
      <button class="back" @click="router.push('/')">去广场看看</button>
    </div>

    <p v-if="loading" class="loader-wrap"><span class="spinner"></span></p>
    <p v-else-if="notFound" class="hint">这家店不存在或已关闭 🥲</p>

    <template v-else-if="shop">
      <section class="hero">
        <div class="s-emoji">{{ shop.emoji || '🏠' }}</div>
        <div class="s-who">
          <div class="title-row">
            <h1>{{ shop.shopName }}</h1>
            <span class="pill" :class="shop.status === 'active' ? 'on' : 'off'">
              {{ shop.status === 'active' ? '营业中' : '休息中' }}
            </span>
          </div>
          <p class="desc">{{ shop.description || '这家店还没有写简介～' }}</p>
          <div class="meta">
            <span v-if="shop.district">📍 {{ shop.district }}</span>
            <span v-if="shop.phone">📞 {{ shop.phone }}</span>
            <span v-if="shop.ownerName">👤 店主 @{{ shop.ownerName }}</span>
            <span>🗓 开店于 {{ dateStr(shop.createTime) }}</span>
          </div>
        </div>
      </section>

      <div class="stats">
        <div class="stat"><b>{{ shop.postCount ?? 0 }}</b><span>在售菜品</span></div>
        <div class="stat"><b>{{ Number(shop.avgRating || 0).toFixed(1) }}</b><span>店铺均分</span></div>
        <div class="stat"><b>{{ shop.reviewCount ?? 0 }}</b><span>累计点评</span></div>
        <div class="stat"><b>{{ shop.favoriteCount ?? 0 }}</b><span>累计收藏</span></div>
      </div>

      <div class="sec-head">
        <h2>店内菜品</h2>
        <span class="sec-sub">共 {{ posts.length }} 道</span>
      </div>

      <div v-if="posts.length" class="grid">
        <article v-for="p in posts" :key="p.id" class="card" @click="openPost(p.id)">
          <div class="c-emoji">{{ p.emoji }}</div>
          <div class="c-body">
            <span class="tag">{{ p.category }}</span>
            <h3>{{ p.title }}</h3>
            <p class="excerpt">{{ p.content }}</p>
            <div class="c-foot">
              <span class="c-stars">{{ stars(p.rating) }}</span>
              <span>{{ Number(p.rating || 0).toFixed(1) }} · 💬 {{ p.reviewCount ?? 0 }} · ★ {{ p.favoriteCount ?? 0 }}</span>
            </div>
          </div>
        </article>
      </div>
      <p v-else class="hint">这家店还没有上架菜品，再等等吧～</p>
    </template>
  </div>
</template>

<style scoped>
.shop-detail{ position:relative; max-width:1000px; margin:0 auto; padding:24px 24px 90px; z-index:1; }

.bg-orbs{ position:absolute; inset:0; pointer-events:none; z-index:0; }
.bg-orbs span{ position:absolute; font-size:38px; opacity:.14; animation:orb 9s ease-in-out infinite; filter:blur(.3px); }
.o1{ left:4%;  top:12%; } .o2{ left:82%; top:10%; animation-delay:.8s; }
.o3{ left:10%; top:70%; animation-delay:1.6s; } .o4{ left:88%; top:66%; animation-delay:2.4s; }
.o5{ left:44%; top:6%;  animation-delay:3.2s; } .o6{ left:62%; top:82%; animation-delay:1.1s; }
.o7{ left:26%; top:40%; animation-delay:2.7s; font-size:50px; } .o8{ left:72%; top:44%; animation-delay:3.6s; }
@keyframes orb{ 0%,100%{ transform:translateY(0) rotate(-6deg); } 50%{ transform:translateY(-22px) rotate(8deg); } }

.topbar{ position:relative; z-index:2; display:flex; align-items:center; justify-content:space-between; gap:10px; margin-bottom:18px; }
.back{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:8px 14px; border-radius:11px; cursor:pointer; font-weight:600; transition:.2s; font-family:inherit; }
.back:hover{ border-color:var(--orange); color:var(--tomato); }

.loader-wrap{ position:relative; z-index:2; display:flex; justify-content:center; padding:60px 0; }
.spinner{ width:32px; height:32px; border-radius:50%; border:3px solid #f0e6db; border-top-color:var(--tomato); animation:spin .8s linear infinite; }
@keyframes spin{ to{ transform:rotate(360deg); } }

.hero{ position:relative; z-index:2; display:flex; align-items:center; gap:20px; flex-wrap:wrap;
  background:linear-gradient(150deg,#ff8c42 0%,#ff5a3c 55%,#e23b3b 100%);
  border-radius:22px; padding:24px 28px; color:#fff; box-shadow:var(--ring); overflow:hidden; }
.hero::before{ content:""; position:absolute; inset:0;
  background:radial-gradient(circle at 85% 15%,rgba(255,255,255,.25),transparent 45%); pointer-events:none; }
.s-emoji{ position:relative; z-index:2; width:74px; height:74px; border-radius:20px; background:rgba(255,255,255,.22);
  display:flex; align-items:center; justify-content:center; font-size:40px; flex-shrink:0; }
.s-who{ position:relative; z-index:2; flex:1; min-width:200px; }
.title-row{ display:flex; align-items:center; gap:10px; flex-wrap:wrap; }
.title-row h1{ font-size:23px; font-weight:800; }
.pill{ font-size:11.5px; font-weight:800; padding:3px 10px; border-radius:999px; }
.pill.on{ background:rgba(255,255,255,.9); color:var(--ok); }
.pill.off{ background:rgba(0,0,0,.22); color:#fff; }
.desc{ margin-top:7px; font-size:13.5px; line-height:1.6; opacity:.94; }
.meta{ display:flex; flex-wrap:wrap; gap:14px; margin-top:10px; font-size:12.5px; opacity:.9; }

.stats{ position:relative; z-index:2; display:grid; grid-template-columns:repeat(4,1fr); gap:14px; margin-top:16px; }
.stat{ background:#fff; border-radius:16px; padding:16px 14px; text-align:center;
  box-shadow:0 8px 20px rgba(255,90,60,.08); border:1px solid #f6ede2; }
.stat b{ display:block; font-size:24px; font-weight:800; color:var(--tomato); line-height:1.15; }
.stat span{ font-size:12.5px; color:var(--muted); }

.sec-head{ position:relative; z-index:2; display:flex; align-items:baseline; gap:10px; margin:26px 0 14px; }
.sec-head h2{ font-size:18px; font-weight:800; }
.sec-sub{ font-size:12.5px; color:var(--muted); }

.grid{ position:relative; z-index:2; display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.card{ background:#fff; border-radius:16px; overflow:hidden; cursor:pointer;
  box-shadow:0 8px 20px rgba(0,0,0,.05); transition:transform .2s, box-shadow .2s;
  animation:cardIn .45s backwards; display:flex; flex-direction:column; }
.card:hover{ transform:translateY(-4px); box-shadow:0 14px 28px rgba(255,90,60,.18); }
@keyframes cardIn{ from{ opacity:0; transform:translateY(14px); } to{ opacity:1; transform:translateY(0); } }
.c-emoji{ font-size:40px; padding:18px 18px 0; }
.c-body{ padding:14px 18px 18px; }
.tag{ display:inline-block; font-size:11.5px; color:var(--tomato); background:#fff0ea;
  padding:3px 9px; border-radius:10px; margin-bottom:8px; }
.card h3{ font-size:16px; margin-bottom:6px; }
.excerpt{ font-size:13px; color:var(--muted); line-height:1.5;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.c-foot{ display:flex; flex-direction:column; gap:2px; margin-top:10px; font-size:12px; color:var(--muted); }
.c-stars{ color:#f5a623; letter-spacing:1px; }

.hint{ position:relative; z-index:2; color:var(--muted); padding:34px 0; text-align:center; font-size:14px; }

@media (max-width:760px){
  .grid{ grid-template-columns:repeat(2,1fr); }
  .stats{ grid-template-columns:repeat(2,1fr); }
}
@media (max-width:480px){
  .grid{ grid-template-columns:1fr; }
}
</style>
