<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { authUser } from '../composables/useAuth.js'
import { useFavorites } from '../composables/useFavorites.js'

const router = useRouter()
const posts = ref([])
const loading = ref(false)
const tab = ref('mine') // 'mine' | 'fav'

const { ids } = useFavorites()

const mine = computed(() =>
  posts.value.filter(p => p.author === authUser.value)
)
const favList = computed(() =>
  posts.value.filter(p => ids.value.has(Number(p.id)))
)

async function load() {
  loading.value = true
  try {
    const r = await fetch('/api/posts')
    posts.value = await r.json()
  } finally {
    loading.value = false
  }
}

function openPost(id) { router.push(`/post/${id}`) }
function goHome() { router.push('/') }

onMounted(load)
</script>

<template>
  <div class="profile">
    <!-- 漂浮装饰，呼应登录页 / 首页 -->
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>

    <button class="back" @click="goHome">← 返回广场</button>

    <!-- 用户信息卡 -->
    <section class="hero">
      <div class="avatar">🧑‍🍳</div>
      <div class="who">
        <h1>{{ authUser }}</h1>
        <p>美食社区 · 私藏地图管理员</p>
      </div>
      <div class="stats">
        <div class="stat"><b>{{ mine.length }}</b><span>我的发布</span></div>
        <div class="stat"><b>{{ favList.length }}</b><span>我的收藏</span></div>
      </div>
    </section>

    <!-- 分段切换 -->
    <nav class="tabs">
      <button :class="{ on: tab === 'mine' }" @click="tab = 'mine'">我的发布</button>
      <button :class="{ on: tab === 'fav' }" @click="tab = 'fav'">我的收藏</button>
    </nav>

    <p v-if="loading" class="loader-wrap"><span class="spinner"></span></p>

    <div v-else-if="tab === 'mine'" class="grid">
      <article v-for="p in mine" :key="p.id" class="card" @click="openPost(p.id)">
        <div class="emoji">{{ p.emoji }}</div>
        <div class="body">
          <span class="tag">{{ p.category }}</span>
          <h3>{{ p.title }}</h3>
          <p class="excerpt">{{ p.content }}</p>
        </div>
      </article>
      <p v-if="!mine.length" class="hint">还没有发布过美食，去广场点击「＋」分享第一道吧～</p>
    </div>

    <div v-else class="grid">
      <article v-for="p in favList" :key="p.id" class="card" @click="openPost(p.id)">
        <div class="emoji">{{ p.emoji }}</div>
        <div class="body">
          <span class="tag">{{ p.category }}</span>
          <h3>{{ p.title }}</h3>
          <p class="excerpt">{{ p.content }}</p>
        </div>
      </article>
      <p v-if="!favList.length" class="hint">还没有收藏，去广场把喜欢的美食 ★ 收藏起来吧～</p>
    </div>
  </div>
</template>

<style scoped>
.profile{ position:relative; max-width:1000px; margin:0 auto; padding:24px 24px 90px; z-index:1; }

/* 漂浮装饰 */
.bg-orbs{ position:absolute; inset:0; pointer-events:none; z-index:0; }
.bg-orbs span{ position:absolute; font-size:38px; opacity:.14; animation:orb 9s ease-in-out infinite; filter:blur(.3px); }
.o1{ left:4%;  top:12%; } .o2{ left:82%; top:10%; animation-delay:.8s; }
.o3{ left:10%; top:70%; animation-delay:1.6s; } .o4{ left:88%; top:66%; animation-delay:2.4s; }
.o5{ left:44%; top:6%;  animation-delay:3.2s; } .o6{ left:62%; top:82%; animation-delay:1.1s; }
.o7{ left:26%; top:40%; animation-delay:2.7s; font-size:50px; } .o8{ left:72%; top:44%; animation-delay:3.6s; }
@keyframes orb{ 0%,100%{ transform:translateY(0) rotate(-6deg); } 50%{ transform:translateY(-22px) rotate(8deg); } }

.back{ position:relative; z-index:2; border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:8px 14px; border-radius:11px; cursor:pointer; font-weight:600; margin-bottom:18px; transition:.2s; }
.back:hover{ border-color:var(--orange); color:var(--tomato); }

.loader-wrap{ position:relative; z-index:2; display:flex; justify-content:center; padding:50px 0; }
.spinner{ width:32px; height:32px; border-radius:50%; border:3px solid #f0e6db; border-top-color:var(--tomato); animation:spin .8s linear infinite; }
@keyframes spin{ to{ transform:rotate(360deg); } }

/* 用户卡：呼应登录页渐变 */
.hero{ position:relative; z-index:2; display:flex; align-items:center; gap:18px; flex-wrap:wrap;
  background:linear-gradient(150deg,#ff8c42 0%,#ff5a3c 55%,#e23b3b 100%);
  border-radius:22px; padding:24px 28px; color:#fff; box-shadow:var(--ring); overflow:hidden; }
.hero::before{ content:""; position:absolute; inset:0;
  background:radial-gradient(circle at 85% 15%,rgba(255,255,255,.25),transparent 45%); pointer-events:none; }
.avatar{ position:relative; z-index:2; width:62px; height:62px; border-radius:18px; background:rgba(255,255,255,.22);
  display:flex; align-items:center; justify-content:center; font-size:34px; }
.who{ position:relative; z-index:2; flex:1; min-width:140px; }
.who h1{ font-size:22px; font-weight:800; }
.who p{ margin-top:4px; font-size:13px; opacity:.9; }
.stats{ position:relative; z-index:2; display:flex; gap:22px; }
.stat{ text-align:center; }
.stat b{ display:block; font-size:22px; font-weight:800; }
.stat span{ font-size:12px; opacity:.9; }

/* 分段切换 */
.tabs{ position:relative; z-index:2; display:flex; gap:8px; margin:22px 0 18px; }
.tabs button{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:9px 20px; border-radius:20px; font-size:14px; font-weight:600; cursor:pointer; transition:.2s; }
.tabs button:hover{ border-color:var(--orange); color:var(--orange); }
.tabs button.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }

.hint{ position:relative; z-index:2; color:var(--muted); padding:30px 0; text-align:center; font-size:14px; }

.grid{ position:relative; z-index:2; display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.card{ background:#fff; border-radius:16px; overflow:hidden; cursor:pointer;
  box-shadow:0 8px 20px rgba(0,0,0,.05); transition:transform .2s, box-shadow .2s;
  animation:cardIn .45s backwards; display:flex; flex-direction:column; }
.card:hover{ transform:translateY(-4px); box-shadow:0 14px 28px rgba(255,90,60,.18); }
@keyframes cardIn{ from{ opacity:0; transform:translateY(14px); } to{ opacity:1; transform:translateY(0); } }
.emoji{ font-size:40px; padding:18px 18px 0; }
.body{ padding:14px 18px 18px; }
.tag{ display:inline-block; font-size:11.5px; color:var(--tomato); background:#fff0ea;
  padding:3px 9px; border-radius:10px; margin-bottom:8px; }
.card h3{ font-size:16px; margin-bottom:6px; }
.excerpt{ font-size:13px; color:var(--muted); line-height:1.5;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }

@media (max-width:760px){ .grid{ grid-template-columns:repeat(2,1fr); } }
@media (max-width:480px){ .grid{ grid-template-columns:1fr; } .stats{ width:100%; justify-content:flex-start; } }
</style>
