<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useFavorites } from '../composables/useFavorites.js'
import { useLikes } from '../composables/useLikes.js'
import { useReviews } from '../composables/useReviews.js'
import { useToast } from '../composables/useToast.js'
import { authUser, getToken } from '../composables/useAuth.js'
import { catPhoto } from '../data/categories.js'
import { useFoodMeta } from '../composables/useFoodMeta.js'
import { useGrowth } from '../composables/useGrowth.js'

const route = useRoute()
const router = useRouter()
const { toast } = useToast()
const { noteTypeOf, calorieOf, dietTagsOf, serveOf, avgPriceOf, hoursOf, openStatusOf } = useFoodMeta()
const growth = useGrowth()

// 返回上一个页面；直接打开详情链接没有历史时才回首页
function goBack() {
  if (window.history.state && window.history.state.back != null) router.back()
  else router.push('/')
}
const post = ref(null)
const notFound = ref(false)
const loading = ref(false)

const { isFav, toggle } = useFavorites()
const { isLiked, countOf, seed: seedLikes, toggle: toggleLike } = useLikes()
const { getReviews, displayRating, add } = useReviews()

const myRating = ref(5)
const myComment = ref('')
const reviewMsg = ref('')
const preview = ref(false)
const brokenImg = ref(false)
const brokenCatPhoto = ref(false)
const submitting = ref(false)

const reviewsList = computed(() => (post.value ? getReviews(post.value.id) : []))
const avg = computed(() => (post.value ? displayRating(post.value) : 0))
const likeCount = computed(() => (post.value ? countOf(post.value.id, post.value.likeCount || 0) : 0))
// 卡片元数据：类型 / 热量 / 忌口 / 堂食打包 / 人均 / 营业时间
const noteType = computed(() => (post.value ? noteTypeOf(post.value) : 'plant'))
const cal = computed(() => (post.value ? calorieOf(post.value) : null))
const dietTags = computed(() => (post.value ? dietTagsOf(post.value) : []))
const serve = computed(() => (post.value ? serveOf(post.value) : ''))
const price = computed(() => (post.value ? avgPriceOf(post.value) : 0))
const hours = computed(() => (post.value ? hoursOf(post.value) : ['', '']))
const openSt = computed(() => (post.value ? openStatusOf(post.value) : null))
const coverImg = computed(() => {
  if (!post.value) return ''
  if (post.value.imageUrl && !brokenImg.value) return post.value.imageUrl
  const photo = catPhoto(post.value.category)
  return photo && !brokenCatPhoto.value ? photo : ''
})
function onCoverError() {
  if (post.value?.imageUrl && !brokenImg.value) brokenImg.value = true
  else brokenCatPhoto.value = true
}

onMounted(async () => {
  loading.value = true
  try {
    // 带 token 请求：后端才会返回 liked / favorited，点赞按钮状态才准
    const t = getToken()
    const r = await fetch(`/api/posts/${route.params.id}`, t ? { headers: { Authorization: `Bearer ${t}` } } : undefined)
    if (r.status === 404) { notFound.value = true; return }
    post.value = await r.json()
    seedLikes([post.value])
  } catch {
    notFound.value = true
  } finally {
    loading.value = false
  }
})

function onFav() { if (post.value) toggle(post.value.id) }
async function onLike() { if (post.value) await toggleLike(post.value.id, post.value.likeCount || 0) }
function goProfile() { router.push('/profile') }
function goMap() { router.push('/map') }
function goRanking() { router.push('/ranking') }

/** 私信商家：优先店主账号，没有则找作者；复用时直接进已有会话 */
function chatMerchant() {
  if (!post.value) return
  const peer = post.value.shopOwner || post.value.author
  if (!peer) { toast('这家店还没开通私信', 'info'); return }
  if (peer === authUser.value) { toast('这是你自己发布的笔记哦', 'info'); return }
  router.push(`/chat?peer=${encodeURIComponent(peer)}`)
}

async function submitReview() {
  if (!post.value) return
  if (!myComment.value.trim()) { reviewMsg.value = '写点感受再发布吧～'; return }
  if (submitting.value) return
  submitting.value = true
  try {
    await add(post.value.id, {
      author: authUser.value || '匿名',
      rating: myRating.value,
      comment: myComment.value.trim()
    })
    post.value.reviewCount = (post.value.reviewCount || 0) + 1
    // 成长体系：评价 +10 积分、打卡徽章进度、口味挑战（记录尝试的分类）
    growth.onAction('comment', { category: post.value.category })
    myComment.value = ''
    myRating.value = 5
    reviewMsg.value = ''
    toast('评价已发布 🎉', 'success')
  } catch (e) {
    reviewMsg.value = e.message || '发布失败，请稍后再试'
  } finally {
    submitting.value = false
  }
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
      <button class="back" @click="goBack">← 返回广场</button>
      <div class="top-right">
        <button class="mine" @click="goMap">美食地图</button>
        <button class="mine" @click="goRanking">排行榜</button>
        <button class="mine" @click="goProfile">我的</button>
      </div>
    </div>

    <p v-if="loading" class="loader-wrap"><span class="spinner"></span></p>
    <p v-else-if="notFound" class="hint">帖子不存在或已被删除 🥲</p>

    <article v-else-if="post" class="post">
      <div class="cover" :class="{ 'has-img': !!coverImg }">
        <img v-if="coverImg" class="cover-img" :src="coverImg" :alt="post.title" @error="onCoverError" @click="preview = true" />
        <div v-else class="cover-emoji" @click="preview = true">{{ post.emoji }}</div>
        <span class="tag">{{ post.category }}</span>
        <button class="zoom" type="button" @click="preview = true">🔍 看大图</button>
      </div>

      <div class="acts">
        <button class="fav" :class="{ on: isLiked(post.id) }" @click="onLike">
          {{ isLiked(post.id) ? '❤️' : '🤍' }} {{ likeCount }}
        </button>
        <button class="fav" :class="{ on: isFav(post.id) }" @click="onFav">
          {{ isFav(post.id) ? '★ 已收藏' : '☆ 收藏' }}
        </button>
        <span class="acts-hint">💬 {{ post.reviewCount || 0 }} 条评价</span>
      </div>

      <h1>{{ post.title }}</h1>
      <!-- 笔记类型横幅：避雷笔记醒目提示 -->
      <div v-if="noteType === 'avoid'" class="type-banner avoid">⚠️ 这是一篇避雷笔记，真实踩雷反馈，供你下单前参考</div>
      <div v-else class="type-banner plant">🌱 这是一篇种草笔记，作者真心推荐</div>
      <div class="meta">
        <span v-if="post.shopName" class="shop-chip">🏠 {{ post.shopName }}</span>
        <span class="author" @click="goProfile">@{{ post.author }}</span>
        · {{ new Date(post.createdAt).toLocaleDateString() }}
        <button class="dm-btn" type="button" @click="chatMerchant">💬 私信商家</button>
      </div>
      <!-- 菜品信息标签：热量 / 堂食打包 / 忌口 / 人均 / 营业时间 -->
      <div class="info-chips">
        <span class="chip" :class="cal.cls">🔥 热量 {{ cal.text }}</span>
        <span class="chip">🍽️ {{ serve }}</span>
        <span v-for="t in dietTags" :key="t.text" class="chip" :class="t.cls">{{ t.text }}</span>
        <span class="chip">💰 人均 ¥{{ price }}</span>
        <span class="chip" :class="openSt.cls">
          <i class="live-dot"></i>{{ openSt.label }} · {{ hours[0] }}–{{ hours[1] }}
        </span>
      </div>
      <p class="content">{{ post.content }}</p>

      <section class="reviews">
        <div class="rev-head">
          <h2>食客评价</h2>
          <span class="rev-avg">★ {{ avg.toFixed(1) }}<small>（{{ reviewsList.length || post.reviewCount || 0 }} 条）</small></span>
        </div>

        <div class="rev-form" v-if="authUser">
          <div class="rate">
            <span class="rate-label">我的评分</span>
            <button v-for="n in 5" :key="n" type="button" class="star" :class="{ on: myRating >= n }" @click="myRating = n">{{ myRating >= n ? '★' : '☆' }}</button>
          </div>
          <textarea v-model="myComment" rows="2" placeholder="分享你的真实体验，帮大家避坑或种草～"></textarea>
          <div class="rev-msg">{{ reviewMsg }}</div>
          <button class="rev-btn" type="button" :disabled="submitting" @click="submitReview">
            {{ submitting ? '发布中…' : '发布评价' }}
          </button>
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
        <p v-if="!reviewsList.length" class="rev-empty">还没有文字评价，快来抢沙发～</p>
      </section>
    </article>

    <!-- 图片放大预览：teleport 到 body，避免被页面容器的 z-index 困住而盖不住顶部导航 -->
    <Teleport to="body">
      <div v-if="preview" class="lightbox" @click="preview = false">
        <img v-if="coverImg" :src="coverImg" :alt="post && post.title" />
        <div v-else class="lb-emoji">{{ post && post.emoji }}</div>
        <span class="lb-close">✕</span>
        <span class="lb-tip">点击任意处关闭</span>
      </div>
    </Teleport>
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

.cover{ position:relative; margin-bottom:14px; border-radius:18px; overflow:hidden; background:#fff8f0; line-height:0; }
.cover.has-img{ background:#f3e7db; }
.cover-emoji{ height:220px; display:flex; align-items:center; justify-content:center; font-size:92px; line-height:1; cursor:zoom-in;
  background:radial-gradient(circle at 30% 22%, #fffdfa 0%, #fff1e3 45%, #ffe0c9 100%); }
.cover-emoji:hover{ filter:brightness(1.03); }
.cover-img{ width:100%; aspect-ratio:16/9; max-height:360px; object-fit:cover; cursor:zoom-in; display:block; }
.cover .tag{ position:absolute; left:16px; top:16px; display:inline-block; font-size:12px; color:var(--tomato); background:rgba(255,240,234,.94);
  padding:4px 12px; border-radius:11px; font-weight:600; line-height:1.4; }
.zoom{ position:absolute; right:14px; bottom:14px; border:0; background:rgba(255,255,255,.92); color:#8b6a4d;
  font-size:11.5px; padding:5px 11px; border-radius:999px; cursor:pointer; font-family:inherit; line-height:1.5; box-shadow:0 4px 12px rgba(180,120,80,.16); }
.zoom:hover{ color:var(--tomato); }
.acts{ display:flex; align-items:center; gap:10px; margin-bottom:18px; }
.acts-hint{ margin-left:auto; font-size:12.5px; color:#c0aa96; }
.fav{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:8px 14px; border-radius:999px; cursor:pointer; font-weight:700; font-size:13px; transition:.2s; white-space:nowrap; font-family:inherit; }
.fav:hover{ border-color:var(--orange); color:var(--tomato); }
.fav.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }

.dm-btn{ margin-left:12px; border:1.5px solid #ffd9bf; background:#fff3e9; color:var(--tomato); font-size:12.5px;
  font-weight:800; padding:5px 13px; border-radius:999px; cursor:pointer; font-family:inherit; transition:.2s; }
.dm-btn:hover{ background:#ffe9d8; }

/* 图片放大预览 */
.lightbox{ position:fixed; inset:0; z-index:40; display:flex; align-items:center; justify-content:center;
  background:rgba(30,18,10,.9); cursor:zoom-out; animation:lbIn .18s ease; }
@keyframes lbIn{ from{ opacity:0; } to{ opacity:1; } }
.lightbox img{ max-width:90vw; max-height:82vh; border-radius:14px; box-shadow:0 24px 60px rgba(0,0,0,.5); }
.lb-emoji{ font-size:150px; filter:drop-shadow(0 16px 28px rgba(0,0,0,.45)); }
.lb-close{ position:absolute; top:22px; right:24px; width:34px; height:34px; display:flex; align-items:center; justify-content:center;
  border-radius:50%; background:rgba(255,255,255,.18); color:#fff; font-size:15px; }
.lb-tip{ position:absolute; bottom:28px; left:50%; transform:translateX(-50%); font-size:12px; color:rgba(255,255,255,.7); }

.post h1{ font-size:27px; margin-bottom:10px; line-height:1.3; }
/* 笔记类型横幅 */
.type-banner{ border-radius:12px; padding:9px 14px; font-size:12.5px; font-weight:700; margin-bottom:12px; }
.type-banner.plant{ background:#e9f7ee; color:#1d7a3e; border:1px solid #cdeeda; }
.type-banner.avoid{ background:#fdeae6; color:#c23b22; border:1px solid #ffd1c4; }
/* 菜品信息标签 */
.info-chips{ display:flex; flex-wrap:wrap; gap:7px; margin-bottom:18px; }
.chip{ font-size:11.5px; font-weight:700; padding:4px 10px; border-radius:999px; background:#f6eee6; color:#7a6a5d; }
.chip.low{ background:#e9f7ee; color:#1d7a3e; }
.chip.mid{ background:#fff1e0; color:#b07010; }
.chip.high,.chip.warn{ background:#fdeae6; color:#c23b22; }
.chip.safe{ background:#e9f7ee; color:#1d7a3e; }
.chip.on{ background:#e9f7ee; color:#1d7a3e; }
.chip.off{ background:#f1ece5; color:#9b8c7e; }
.live-dot{ width:7px; height:7px; border-radius:50%; display:inline-block; margin-right:4px; background:currentColor; }
.meta{ color:#bba; font-size:13px; margin-bottom:16px; }
.meta .author{ color:var(--tomato); cursor:pointer; font-weight:600; }
.meta .shop-chip{ display:inline-block; background:#fff2e8; color:#b4652f; border:1px solid #ffd9bf;
  border-radius:999px; padding:2px 10px; margin-right:8px; font-size:12.5px; font-weight:700; }
.meta .author:hover{ text-decoration:underline; }
.content{ font-size:16px; line-height:1.85; color:#4a3d33; white-space:pre-wrap; }
</style>
