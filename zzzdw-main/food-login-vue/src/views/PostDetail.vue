<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useFavorites } from '../composables/useFavorites.js'
import { useReviews } from '../composables/useReviews.js'
import { authUser } from '../composables/useAuth.js'

const route = useRoute()
const router = useRouter()
const post = ref(null)
const notFound = ref(false)
const loading = ref(false)

const { isFav, toggle } = useFavorites()
const { getReviews, avgRating, add } = useReviews()

const myRating = ref(5)
const myComment = ref('')
const reviewMsg = ref('')

const reviewsList = computed(() => (post.value ? getReviews(post.value.id) : []))
const avg = computed(() => (post.value ? avgRating(post.value.id) : 0))

onMounted(async () => {
  loading.value = true
  try {
    const r = await fetch(`/api/posts/${route.params.id}`)
    if (r.status === 404) { notFound.value = true; return }
    post.value = await r.json()
  } catch {
    notFound.value = true
  } finally {
    loading.value = false
  }
})

function onFav() { if (post.value) toggle(post.value.id) }
function goProfile() { router.push('/profile') }
function goMap() { router.push('/map') }
function goRanking() { router.push('/ranking') }
function submitReview() {
  if (!post.value) return
  if (!myComment.value.trim()) { reviewMsg.value = '写点感受再发布吧～'; return }
  add(post.value.id, { author: authUser.value || '匿名', rating: myRating.value, comment: myComment.value.trim() })
  myComment.value = ''
  myRating.value = 5
  reviewMsg.value = ''
}
function starStr(n) {
  const f = Math.round(n)
  return '★'.repeat(f) + '☆'.repeat(5 - f)
}
</script>

<template>
  <div class="detail">
    <!-- 漂浮装饰，呼应登录页 / 首页 -->
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>

    <div class="topbar">
      <button class="back" @click="router.push('/')">← 返回广场</button>
      <div class="top-right">
        <button class="mine" @click="goMap">美食地图</button>
        <button class="mine" @click="goRanking">排行榜</button>
        <button class="mine" @click="goProfile">我的</button>
      </div>
    </div>

    <p v-if="loading" class="loader-wrap"><span class="spinner"></span></p>
    <p v-else-if="notFound" class="hint">帖子不存在或已被删除 🥲</p>

    <article v-else-if="post" class="post">
      <div class="cover">
        <div class="emoji">{{ post.emoji }}</div>
        <span class="tag">{{ post.category }}</span>
        <button class="fav" :class="{ on: isFav(post.id) }" @click="onFav">
          {{ isFav(post.id) ? '★ 已收藏' : '☆ 收藏' }}
        </button>
      </div>

      <h1>{{ post.title }}</h1>
      <div class="meta">
        <span class="author" @click="goProfile">@{{ post.author }}</span>
        · {{ new Date(post.createdAt).toLocaleDateString() }}
      </div>
      <p class="content">{{ post.content }}</p>

      <section class="reviews">
        <div class="rev-head">
          <h2>食客评价</h2>
          <span class="rev-avg">★ {{ avg.toFixed(1) }}<small>（{{ reviewsList.length }} 条）</small></span>
        </div>

        <div class="rev-form" v-if="authUser">
          <div class="rate">
            <span class="rate-label">我的评分</span>
            <button v-for="n in 5" :key="n" type="button" class="star" :class="{ on: myRating >= n }" @click="myRating = n">{{ myRating >= n ? '★' : '☆' }}</button>
          </div>
          <textarea v-model="myComment" rows="2" placeholder="分享你的真实体验，帮大家避坑或种草～"></textarea>
          <div class="rev-msg">{{ reviewMsg }}</div>
          <button class="rev-btn" type="button" @click="submitReview">发布评价</button>
        </div>
        <p v-else class="rev-login">登录后即可发表评价</p>

        <ul class="rev-list">
          <li v-for="r in reviewsList" :key="r.id" class="rev-item">
            <div class="rev-top">
              <span class="rev-author">@{{ r.author }}</span>
              <span class="rev-stars">{{ starStr(r.rating) }}</span>
              <span class="rev-date">{{ new Date(r.at).toLocaleDateString() }}</span>
            </div>
            <p class="rev-text">{{ r.comment }}</p>
          </li>
        </ul>
        <p v-if="!reviewsList.length" class="rev-empty">还没有评价，快来抢沙发～</p>
      </section>
    </article>
  </div>
</template>

<style scoped>
.detail{ position:relative; max-width:720px; margin:0 auto; padding:24px 24px 60px; z-index:1; }

/* 漂浮装饰，与登录页 bg-orbs 一致 */
.bg-orbs{ position:absolute; inset:0; pointer-events:none; z-index:0; }
.bg-orbs span{ position:absolute; font-size:38px; opacity:.14; animation:orb 9s ease-in-out infinite; filter:blur(.3px); }
.o1{ left:3%;  top:14%; } .o2{ left:84%; top:12%; animation-delay:.8s; }
.o3{ left:8%;  top:72%; animation-delay:1.6s; } .o4{ left:88%; top:68%; animation-delay:2.4s; }
.o5{ left:46%; top:5%;  animation-delay:3.2s; } .o6{ left:60%; top:84%; animation-delay:1.1s; }
.o7{ left:24%; top:42%; animation-delay:2.7s; font-size:50px; } .o8{ left:74%; top:46%; animation-delay:3.6s; }
@keyframes orb{ 0%,100%{ transform:translateY(0) rotate(-6deg); } 50%{ transform:translateY(-22px) rotate(8deg); } }

.topbar{ position:relative; z-index:2; display:flex; align-items:center; justify-content:space-between; margin-bottom:18px; }
.back, .mine{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted); padding:8px 14px;
  border-radius:11px; cursor:pointer; font-weight:600; transition:.2s; }
.back:hover, .mine:hover{ border-color:var(--orange); color:var(--tomato); }
.top-right{ display:flex; gap:10px; }

.reviews{ position:relative; z-index:2; margin-top:26px; border-top:1px dashed #ecdfd2; padding-top:20px; }
.rev-head{ display:flex; align-items:baseline; justify-content:space-between; margin-bottom:14px; }
.rev-head h2{ font-size:19px; font-weight:800; }
.rev-avg{ font-size:15px; font-weight:800; color:var(--tomato); }
.rev-avg small{ color:var(--muted); font-weight:600; font-size:12px; }

.rev-form{ background:#faf5ef; border-radius:14px; padding:14px; margin-bottom:16px; }
.rate{ display:flex; align-items:center; gap:8px; margin-bottom:10px; }
.rate-label{ font-size:13px; color:var(--muted); font-weight:600; }
.star{ border:0; background:none; cursor:pointer; font-size:22px; color:#e0d4c6; line-height:1; transition:.15s; padding:0; }
.star.on{ color:#f5a623; transform:scale(1.05); }
.rev-form textarea{ width:100%; padding:11px 13px; border:1.5px solid #ecdfd2; border-radius:11px; font-size:14px;
  outline:none; font-family:inherit; resize:vertical; }
.rev-form textarea:focus{ border-color:var(--orange); }
.rev-msg{ color:var(--err); font-size:12.5px; min-height:16px; margin:6px 0; }
.rev-btn{ border:0; border-radius:11px; padding:10px 18px; font-weight:700; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); }
.rev-btn:hover{ filter:brightness(1.05); }
.rev-login{ font-size:13px; color:var(--muted); margin-bottom:14px; }

.rev-list{ list-style:none; display:flex; flex-direction:column; gap:12px; }
.rev-item{ background:#fff; border:1px solid #f0e6db; border-radius:13px; padding:12px 14px; }
.rev-top{ display:flex; align-items:center; gap:10px; margin-bottom:6px; }
.rev-author{ font-size:13.5px; font-weight:700; color:var(--tomato); }
.rev-stars{ font-size:13px; color:#f5a623; letter-spacing:1px; }
.rev-date{ margin-left:auto; font-size:11.5px; color:#bba; }
.rev-text{ font-size:14px; line-height:1.7; color:#4a3d33; white-space:pre-wrap; }
.rev-empty{ color:var(--muted); font-size:13.5px; padding:6px 0; }

.loader-wrap{ position:relative; z-index:2; display:flex; justify-content:center; padding:60px 0; }
.spinner{ width:32px; height:32px; border-radius:50%; border:3px solid #f0e6db; border-top-color:var(--tomato); animation:spin .8s linear infinite; }
@keyframes spin{ to{ transform:rotate(360deg); } }

.hint{ position:relative; z-index:2; color:var(--muted); padding:40px 0; text-align:center; }

.post{ position:relative; z-index:2; background:#fff; border-radius:22px; padding:26px 28px 32px;
  box-shadow:0 18px 44px rgba(255,90,60,.12); animation:cardIn .45s backwards; }
@keyframes cardIn{ from{ opacity:0; transform:translateY(14px); } to{ opacity:1; transform:translateY(0); } }

.cover{ display:flex; align-items:center; gap:14px; margin-bottom:18px; }
.cover .emoji{ font-size:54px; line-height:1; }
.cover .tag{ display:inline-block; font-size:12px; color:var(--tomato); background:#fff0ea;
  padding:4px 12px; border-radius:11px; font-weight:600; }
.fav{ margin-left:auto; border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:8px 16px; border-radius:999px; cursor:pointer; font-weight:700; font-size:13px; transition:.2s; }
.fav:hover{ border-color:var(--orange); color:var(--tomato); }
.fav.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }

.post h1{ font-size:27px; margin-bottom:10px; line-height:1.3; }
.meta{ color:#bba; font-size:13px; margin-bottom:22px; }
.meta .author{ color:var(--tomato); cursor:pointer; font-weight:600; }
.meta .author:hover{ text-decoration:underline; }
.content{ font-size:16px; line-height:1.85; color:#4a3d33; white-space:pre-wrap; }
</style>
