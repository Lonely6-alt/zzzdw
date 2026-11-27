<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { authUser } from '../composables/useAuth.js'
import { useFavorites } from '../composables/useFavorites.js'
import { useGrowth, LEVELS, WEEKLY_TASKS, BADGES } from '../composables/useGrowth.js'

const router = useRouter()
const posts = ref([])
const loading = ref(false)
const tab = ref('mine') // 'mine' | 'fav' | 'badge'

const { ids } = useFavorites()
const growth = useGrowth()

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
function goHome() {
  // 返回上一个页面；直接输入网址进来没有历史时才回首页
  if (window.history.state && window.history.state.back != null) router.back()
  else router.push('/')
}

/* ---------------- 徽章墙 ---------------- */
const badgeGroups = computed(() => {
  const g = {}
  for (const b of BADGES) {
    (g[b.group] = g[b.group] || []).push(b)
  }
  return g
})
const unlockedCount = computed(() =>
  BADGES.filter(b => growth.unlocked.value[b.id]).length
)
function badgeUnlocked(id) { return !!growth.unlocked.value[id] }
function fmtUnlockTime(ts) {
  const d = new Date(ts)
  return `${d.getMonth() + 1}月${d.getDate()}日解锁`
}

/* ---------------- 成长体系 ---------------- */
const couponList = computed(() => Object.entries(growth.coupons.value).map(([k, c]) => ({ ...c, key: k })).reverse())
function pct(cur, target) { return Math.min(100, Math.round((cur / target) * 100)) }

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
        <p>
          <span class="lv-pill">{{ growth.level.value.emoji }} Lv.{{ growth.level.value.lv }} {{ growth.level.value.name }}</span>
          美食社区 · 吃货
        </p>
      </div>
      <div class="stats">
        <div class="stat"><b>{{ mine.length }}</b><span>我的发布</span></div>
        <div class="stat"><b>{{ favList.length }}</b><span>我的收藏</span></div>
        <div class="stat"><b>{{ growth.points.value }}</b><span>吃货积分</span></div>
      </div>
      <button class="shop-entry" @click="router.push('/shop')">🏠 我的店铺</button>
    </section>

    <!-- ===== 吃货成长中心 ===== -->
    <section class="growth">
      <!-- 积分等级卡 -->
      <div class="g-card level-card">
        <div class="g-head">
          <h3>{{ growth.level.value.emoji }} Lv.{{ growth.level.value.lv }} {{ growth.level.value.name }}</h3>
          <span class="g-points">{{ growth.points.value }} 积分</span>
        </div>
        <div class="lv-bar">
          <div class="lv-fill" :style="{ width: (growth.levelProgress.value * 100) + '%' }"></div>
        </div>
        <p class="lv-next">
          <template v-if="growth.nextLevel.value">
            距离下一级「{{ growth.nextLevel.value.emoji }} {{ growth.nextLevel.value.name }}」还差 {{ growth.nextLevel.value.min - growth.points.value }} 积分
          </template>
          <template v-else>已是最高等级，站在吃货之巅 👑</template>
        </p>
        <div class="lv-all">
          <span
            v-for="l in LEVELS"
            :key="l.lv"
            class="lv-node"
            :class="{ on: growth.points.value >= l.min }"
          >{{ l.emoji }} Lv.{{ l.lv }} {{ l.name }}</span>
        </div>
      </div>

      <!-- 每周任务 -->
      <div class="g-card">
        <div class="g-head">
          <h3>📅 每周任务</h3>
          <span class="g-sub">每周一凌晨重置，做完就领积分</span>
        </div>
        <ul class="task-list">
          <li v-for="t in WEEKLY_TASKS" :key="t.key" class="task" :class="{ done: growth.taskDone(t.key) }">
            <span class="t-emoji">{{ t.emoji }}</span>
            <div class="t-main">
              <p class="t-title">{{ t.title }}</p>
              <div class="t-bar">
                <div class="t-fill" :style="{ width: pct(growth.taskProgress(t.key), t.target) + '%' }"></div>
              </div>
              <span class="t-count">{{ Math.min(growth.taskProgress(t.key), t.target) }} / {{ t.target }}</span>
            </div>
            <button
              class="t-claim"
              type="button"
              :disabled="!growth.taskDone(t.key) || growth.taskClaimed(t.key)"
              :class="{ claimed: growth.taskClaimed(t.key) }"
              @click="growth.claimTask(t.key)"
            >
              {{ growth.taskClaimed(t.key) ? '已领取' : (growth.taskDone(t.key) ? `领 ${t.points} 分` : `+${t.points}`) }}
            </button>
          </li>
        </ul>
      </div>

      <!-- 积分商城：奖品直接展示，不再需要点「去兑换」 -->
      <div class="g-card">
        <div class="g-head">
          <h3>🎁 积分好礼</h3>
          <span class="g-sub">兑完自动收入囊中</span>
        </div>
        <p class="g-sub">已拥有 {{ growth.couponCount.value }} 件好礼 · 积够就能兑</p>
        <div class="reward-shop">
          <div v-for="c in growth.rewards.value" :key="c.id" class="reward" :class="{ lack: growth.points.value < c.cost }">
            <span class="c-emoji">{{ c.emoji }}</span>
            <div class="c-info">
              <b>{{ c.name }}</b>
              <span class="c-tag">{{ c.tag }}</span>
              <i>{{ c.desc }}</i>
            </div>
            <button class="c-buy" type="button" :disabled="growth.points.value < c.cost" @click="growth.exchange(c.id)">
              {{ growth.points.value >= c.cost ? `${c.cost} 分兑换` : `还差 ${c.cost - growth.points.value} 分` }}
            </button>
          </div>
        </div>
        <div v-if="couponList.length" class="my-coupons">
          <span v-for="c in couponList" :key="c.key" class="my-coupon">
            🎁 {{ c.name }} · 码 {{ c.code }}
          </span>
        </div>
      </div>
    </section>

    <!-- 分段切换 -->
    <nav class="tabs">
      <button :class="{ on: tab === 'mine' }" @click="tab = 'mine'">我的发布</button>
      <button :class="{ on: tab === 'fav' }" @click="tab = 'fav'">我的收藏</button>
      <button :class="{ on: tab === 'badge' }" @click="tab = 'badge'">
        🎖️ 吃货徽章（{{ unlockedCount }}/{{ BADGES.length }}）
      </button>
    </nav>

    <p v-if="loading" class="loader-wrap"><span class="spinner"></span></p>

    <!-- 徽章墙 -->
    <section v-else-if="tab === 'badge'" class="badge-wall">
      <div v-for="(list, gName) in badgeGroups" :key="gName" class="badge-group">
        <h3 class="bg-title">{{ gName }}</h3>
        <div class="badge-grid">
          <div
            v-for="b in list"
            :key="b.id"
            class="badge"
            :class="{ on: badgeUnlocked(b.id) }"
          >
            <span class="b-emoji">{{ badgeUnlocked(b.id) ? b.emoji : '🔒' }}</span>
            <b class="b-name">{{ b.name }}</b>
            <span class="b-desc">{{ b.desc }}</span>
            <span v-if="badgeUnlocked(b.id)" class="b-time">{{ fmtUnlockTime(growth.unlocked.value[b.id]) }}</span>
            <span v-else class="b-time locked">未解锁</span>
          </div>
        </div>
      </div>
      <p class="badge-tip">发布笔记、写评价、尝试新口味都能点亮徽章哦～</p>
    </section>

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
.who p{ margin-top:4px; font-size:13px; opacity:.9; display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.lv-pill{ background:rgba(255,255,255,.92); color:var(--tomato); font-weight:800; font-size:12px;
  padding:3px 10px; border-radius:999px; }
.stats{ position:relative; z-index:2; display:flex; gap:22px; }
.stat{ text-align:center; }
.stat b{ display:block; font-size:22px; font-weight:800; }
.stat span{ font-size:12px; opacity:.9; }
.shop-entry{ position:relative; z-index:2; border:1.5px solid rgba(255,255,255,.55); background:rgba(255,255,255,.18);
  color:#fff; border-radius:999px; padding:9px 18px; font-size:13.5px; font-weight:700; cursor:pointer;
  font-family:inherit; transition:.2s; white-space:nowrap; }
.shop-entry:hover{ background:#fff; color:var(--tomato); }

/* ===== 成长中心 ===== */
.growth{ position:relative; z-index:2; display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:18px; }
.g-card{ background:#fff; border-radius:18px; padding:16px 18px; border:1px solid #f6ede2;
  box-shadow:0 8px 20px rgba(255,90,60,.07); }
.level-card{ grid-column:1 / -1; background:linear-gradient(130deg,#fff7f0,#fff0e6); }
.g-head{ display:flex; align-items:center; justify-content:space-between; gap:10px; margin-bottom:10px; }
.g-head h3{ margin:0; font-size:15.5px; font-weight:800; }
.g-points{ font-size:13px; font-weight:800; color:var(--tomato); }
.g-sub{ font-size:11.5px; color:var(--muted); }
.lv-bar{ height:10px; background:#f4e8dc; border-radius:999px; overflow:hidden; }
.lv-fill{ height:100%; border-radius:999px; background:linear-gradient(90deg,var(--orange),var(--tomato));
  transition:width .5s ease; }
.lv-next{ margin:8px 0 10px; font-size:12px; color:#9b8c7e; }
.lv-all{ display:flex; flex-wrap:wrap; gap:7px; }
.lv-node{ font-size:11px; font-weight:700; padding:4px 10px; border-radius:999px; background:#f4e8dc; color:#a98f78; }
.lv-node.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); color:#fff; box-shadow:0 4px 10px rgba(255,90,60,.25); }

.task-list{ list-style:none; margin:0; padding:0; display:flex; flex-direction:column; gap:10px; }
.task{ display:flex; align-items:center; gap:10px; }
.t-emoji{ font-size:20px; flex-shrink:0; }
.t-main{ flex:1; min-width:0; }
.t-title{ margin:0; font-size:12.5px; font-weight:700; color:var(--ink); }
.t-bar{ height:6px; background:#f4e8dc; border-radius:999px; margin-top:5px; overflow:hidden; }
.t-fill{ height:100%; background:linear-gradient(90deg,#ffaf5e,var(--tomato)); border-radius:999px; transition:width .3s; }
.task.done .t-fill{ background:linear-gradient(90deg,#43c07a,#2f9a5d); }
.t-count{ font-size:10.5px; color:var(--muted); display:block; margin-top:3px; }
.t-claim{ flex-shrink:0; border:0; border-radius:999px; padding:6px 12px; font-size:11.5px; font-weight:800;
  cursor:pointer; color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato)); font-family:inherit; transition:.2s; }
.t-claim:disabled{ opacity:.45; cursor:not-allowed; }
.t-claim.claimed{ background:#e7f6ec; color:#1d7a3e; opacity:1; }
.task.done .t-claim:not(.claimed):not(:disabled){ animation:pulse 1.2s infinite; }
@keyframes pulse{ 0%,100%{ box-shadow:0 0 0 0 rgba(255,90,60,.35); } 50%{ box-shadow:0 0 0 6px rgba(255,90,60,0); } }

.reward-shop{ display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:9px; margin-top:10px;
  max-height:286px; overflow-y:auto; padding-right:4px; }
.reward{ display:flex; align-items:center; gap:9px; border:1.5px dashed #ffd9b0; background:#fffaf5;
  border-radius:13px; padding:9px 10px; min-width:0; }
.reward.lack{ opacity:.62; }
.c-emoji{ font-size:22px; flex-shrink:0; }
.c-info{ flex:1; min-width:0; }
.c-info b{ display:block; font-size:12.5px; color:var(--ink); }
.c-tag{ display:inline-block; font-size:10px; font-weight:800; color:#b56a1f; background:#ffeddb;
  border-radius:999px; padding:1px 7px; margin:2px 0 3px; }
.c-info i{ display:block; font-style:normal; font-size:10.5px; color:var(--muted); line-height:1.3; }
.c-buy{ flex-shrink:0; border:0; border-radius:999px; padding:6px 10px; font-size:11px; font-weight:800;
  color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato)); cursor:pointer; font-family:inherit;
  white-space:nowrap; }
.c-buy:disabled{ opacity:.55; cursor:not-allowed; background:#d9c8b8; }
.my-coupons{ display:flex; flex-wrap:wrap; gap:7px; margin-top:12px; }
.my-coupon{ font-size:11px; font-weight:700; padding:4px 10px; border-radius:999px; background:#e9f7ee; color:#1d7a3e; }
@media (max-width:520px){ .reward-shop{ grid-template-columns:1fr; } }

/* ===== 分段切换 ===== */
.tabs{ position:relative; z-index:2; display:flex; gap:8px; margin:22px 0 18px; flex-wrap:wrap; }
.tabs button{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:9px 20px; border-radius:20px; font-size:14px; font-weight:600; cursor:pointer; transition:.2s; }
.tabs button:hover{ border-color:var(--orange); color:var(--orange); }
.tabs button.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }

/* ===== 徽章墙 ===== */
.badge-wall{ position:relative; z-index:2; display:flex; flex-direction:column; gap:18px; }
.badge-group h3{ margin:0 0 10px; font-size:15px; font-weight:800; }
.badge-grid{ display:grid; grid-template-columns:repeat(4,1fr); gap:12px; }
.badge{ background:#faf5ef; border:1.5px solid #f0e6db; border-radius:16px; padding:14px 12px;
  text-align:center; transition:.2s; position:relative; overflow:hidden; }
.badge.on{ background:linear-gradient(150deg,#fff6e9,#fff0e0); border-color:#ffd9b0;
  box-shadow:0 8px 18px rgba(255,150,60,.14); }
.badge.on::after{ content:"✦ 已点亮"; position:absolute; top:8px; right:-26px; transform:rotate(38deg);
  font-size:9px; font-weight:800; color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato));
  padding:2px 30px; letter-spacing:1px; }
.b-emoji{ font-size:30px; display:block; filter:grayscale(1); opacity:.45; }
.badge.on .b-emoji{ filter:none; opacity:1; animation:badgeIn .4s ease; }
@keyframes badgeIn{ from{ transform:scale(.5); opacity:0; } to{ transform:scale(1); opacity:1; } }
.b-name{ display:block; font-size:12.5px; font-weight:800; margin-top:7px; color:var(--muted); }
.badge.on .b-name{ color:var(--tomato); }
.b-desc{ display:block; font-size:10.5px; color:#a09183; margin-top:4px; line-height:1.4; }
.b-time{ display:block; font-size:10px; margin-top:6px; color:#c8a25c; font-weight:700; }
.b-time.locked{ color:#c4ab94; }
.badge-tip{ text-align:center; font-size:12px; color:var(--muted); margin:4px 0 0; }

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

@media (max-width:760px){ .grid,.badge-grid{ grid-template-columns:repeat(2,1fr); } .growth{ grid-template-columns:1fr; } }
@media (max-width:480px){ .grid,.badge-grid{ grid-template-columns:1fr; } .stats{ width:100%; justify-content:flex-start; } }
</style>
