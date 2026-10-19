<script setup>
// 发现页：定位是「策展 + 探索」，内容与首页刻意区分开
// 首页 = 全站聚合广场（按美食类型分类浏览 + 今日精选 + 热门点评）
// 发现 = 场景策展（按吃喝场景，彻底绕开首页那 8 个美食分类）/ 盲盒 / 冷门宝藏 / 动态 / 关注
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useReviews } from '../composables/useReviews.js'
import { useFavorites } from '../composables/useFavorites.js'
import { useOrder } from '../composables/useOrder.js'
import { catBg } from '../data/categories.js'

const router = useRouter()
const { avgRating, count: reviewCount } = useReviews()
const { isFav, toggle } = useFavorites()
const { openOrder } = useOrder()

const posts = ref([])
const loading = ref(false)
const keyword = ref('')

// ===== 场景策展：按「吃喝场景」而非美食类型聚合，彻底绕开首页那 8 个分类 =====
// 纯关键词匹配（不映射 category）：同一道菜可以同时命中多个场景，
// 比如一锅火锅既在「深夜场」也在「聚餐局」——这正是发现页不同于首页分类浏览的意义
const SCENES = [
  {
    key: 'solo', icon: '🧍', name: '一人食', desc: '一个人也要好好吃饭',
    bg: 'linear-gradient(135deg,#2f6f8f 0%,#48a0a8 100%)',
    kw: ['一人食', '一个人', '一人', '吧台', '定食', '独食', '工作日中午', '单人', '自己吃', '坐一下午']
  },
  {
    key: 'party', icon: '🥂', name: '聚餐局', desc: '叫上朋友，热热闹闹',
    bg: 'linear-gradient(135deg,#c0492f 0%,#e8743b 100%)',
    kw: ['聚餐', '朋友', '闺蜜', '生日', '部门', '团建', '请客', '聚会', '多人', '分着吃', '两个人', '分享', '一起', '拼', '热闹', '火锅', '烧烤', '串', '生蚝', '五花肉']
  },
  {
    key: 'tea', icon: '🍰', name: '下午茶', desc: '偷得浮生半日闲',
    bg: 'linear-gradient(135deg,#b8477d 0%,#ec7aa8 100%)',
    kw: ['下午茶', '蛋糕', '咖啡', '拿铁', '甜点', '奶茶', '可颂', '戚风', '甜品', '松饼', '舒芙蕾', '美式', '玛奇朵', '焙茶', '耶加', '燕麦']
  },
  {
    key: 'night', icon: '🌙', name: '深夜场', desc: '凌晨两点还亮着灯',
    bg: 'linear-gradient(135deg,#3a2c5e 0%,#6b4a8f 100%)',
    kw: ['深夜', '夜宵', '宵夜', '啤酒', '冰啤', '生啤', '酒馆', '凌晨', '半夜', '居酒屋', '烧烤', '路边', '小马扎', '加班', '续命', '锅', '火锅', '串']
  },
  {
    key: 'light', icon: '🌿', name: '轻体期', desc: '吃得清爽也照样满足',
    bg: 'linear-gradient(135deg,#2f7a4d 0%,#5cb47a 100%)',
    kw: ['低卡', '健身', '减脂', '轻食', '沙拉', '蛋白', '能量', '蔬菜', '热量', '清爽', '控糖', '牛油果', '藜麦', '羽衣', '波奇', '果昔', '运动']
  }
]

const activeKey = ref(SCENES[0].key)

// 场景选帖：纯关键词匹配，不再用 col.cats 直接映射首页分类，避免「换皮」
function matchScene(p, s) {
  const text = `${p.title || ''}${p.content || ''}${p.category || ''}`
  return s.kw.some(w => text.includes(w))
}

const collections = computed(() =>
  SCENES.map(s => ({
    ...s,
    items: posts.value.filter(p => matchScene(p, s)).slice(0, 8)
  }))
)

const activeCollection = computed(() => collections.value.find(c => c.key === activeKey.value) || null)

// 给任意帖子反查它命中的第一个场景（用于动态时间线 / 搜索结果的场景标签，不再显示首页美食分类）
function sceneOf(p) {
  const s = SCENES.find(s => matchScene(p, s))
  return s ? s.name : ''
}

// ===== 今天吃什么：从全站随机抽一道 =====
const lucky = ref(null)
const rolling = ref(false)
let rollTimer = null

function roll() {
  if (!posts.value.length) return
  rolling.value = true
  clearTimeout(rollTimer)
  // 滚动过程中快速抖动，最后定格在一个随机结果上
  let ticks = 0
  const spin = () => {
    lucky.value = posts.value[Math.floor(Math.random() * posts.value.length)]
    if (++ticks < 8) {
      rollTimer = setTimeout(spin, 60)
    } else {
      rolling.value = false
    }
  }
  spin()
}

// ===== 宝藏挖掘：评价少、但内容写得长（首页按评分/热度排，看不到这些）=====
const treasures = computed(() =>
  [...posts.value]
    .filter(p => reviewCount(p.id) <= 1)
    .sort((a, b) => (b.content || '').length - (a.content || '').length || b.id - a.id)
    .slice(0, 4)
)

// ===== 食客动态：时间线，按发布时间倒序 =====
const timeline = computed(() =>
  [...posts.value]
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt) || b.id - a.id)
    .slice(0, 8)
)

function fromNow(t) {
  const diff = Date.now() - new Date(t).getTime()
  if (!Number.isFinite(diff)) return ''
  const day = Math.floor(diff / 86400000)
  if (day >= 30) return `${Math.floor(day / 30)} 个月前`
  if (day >= 1) return `${day} 天前`
  const hour = Math.floor(diff / 3600000)
  if (hour >= 1) return `${hour} 小时前`
  return '刚刚'
}

// ===== 值得关注：按发帖量 + 均分聚合食客 =====
const authors = computed(() => {
  const map = {}
  for (const p of posts.value) {
    const name = p.author || '匿名'
    if (!map[name]) map[name] = { name, posts: 0, sum: 0, cnt: 0 }
    map[name].posts++
    const av = avgRating(p.id)
    if (av) { map[name].sum += av; map[name].cnt++ }
  }
  return Object.values(map)
    .map(m => ({ ...m, avg: m.cnt ? m.sum / m.cnt : 0 }))
    .sort((a, b) => b.posts - a.posts || b.avg - a.avg)
    .slice(0, 6)
})

// 关注关系存本地，刷新不丢
const FKEY = 'food_follows'
const follows = ref(new Set(JSON.parse(localStorage.getItem(FKEY) || '[]')))
function isFollowed(name) { return follows.value.has(name) }
function toggleFollow(name) {
  if (follows.value.has(name)) follows.value.delete(name)
  else follows.value.add(name)
  follows.value = new Set(follows.value)
  localStorage.setItem(FKEY, JSON.stringify([...follows.value]))
}

// ===== 搜索：发现页自己的搜索，命中后只展示结果列表 =====
const searchResults = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  if (!kw) return []
  return posts.value.filter(p =>
    (p.title || '').toLowerCase().includes(kw) ||
    (p.content || '').toLowerCase().includes(kw) ||
    (p.author || '').toLowerCase().includes(kw) ||
    (p.category || '').toLowerCase().includes(kw)
  )
})

async function loadPosts() {
  loading.value = true
  try {
    const r = await fetch('/api/posts')
    posts.value = await r.json()
    // 进页面先抽一次，避免盲盒区空着
    if (posts.value.length) lucky.value = posts.value[Math.floor(Math.random() * posts.value.length)]
  } finally {
    loading.value = false
  }
}

function openPost(id) { router.push(`/post/${id}`) }
function onOrder(p) { openOrder(p) }
function onFav(id) { toggle(id) }
const firstChar = s => (s || '?').trim().charAt(0).toUpperCase()

onMounted(loadPosts)
onUnmounted(() => clearTimeout(rollTimer))
</script>

<template>
  <div class="discover">
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>

    <div class="topbar">
      <button class="back" @click="router.push('/')">← 返回广场</button>
      <div class="top-right">
        <button class="mine" @click="router.push('/ranking')">排行榜</button>
        <button class="mine" @click="router.push('/map')">美食地图</button>
        <button class="mine" @click="router.push('/profile')">我的</button>
      </div>
    </div>

    <!-- 头部：探索主题，视觉与首页 Hero 明确区分 -->
    <header class="dhead">
      <div class="dhead-copy">
        <span class="badge">🧭 探索模式</span>
        <h1>发现不一样的好味道</h1>
        <p>不按美食分类逛，按吃喝场景找：场景策展 · 盲盒抽取 · 食客动态</p>
      </div>
      <div class="dsearch">
        <span class="ic">🔍</span>
        <input v-model="keyword" placeholder="搜索食客、店铺或口味…" />
        <button v-if="keyword" class="clear" type="button" @click="keyword = ''" aria-label="清空">✕</button>
      </div>
    </header>

    <p v-if="loading" class="loader-wrap"><span class="spinner"></span></p>

    <!-- 有搜索词时，只展示搜索结果，避免和其他板块内容混淆 -->
    <section v-else-if="keyword.trim()" class="block">
      <div class="sec-head">
        <h2>🔍 搜索「{{ keyword.trim() }}」</h2>
        <span class="sec-sub">共 {{ searchResults.length }} 条命中</span>
      </div>
      <div class="result-list">
        <article v-for="p in searchResults" :key="'s' + p.id" class="rs-item" @click="openPost(p.id)">
          <span class="rs-emoji" :style="{ background: catBg(p.category) }">{{ p.emoji }}</span>
          <div class="rs-body">
            <h4>{{ p.title }}</h4>
            <p>{{ p.content }}</p>
            <div class="rs-meta">
              <span class="rs-cat">{{ sceneOf(p) || p.category }}</span>
              <span>@{{ p.author }}</span>
              <span>💬 {{ reviewCount(p.id) }}</span>
            </div>
          </div>
          <button class="rs-fav" :class="{ on: isFav(p.id) }" type="button" @click.stop="onFav(p.id)">
            {{ isFav(p.id) ? '★' : '☆' }}
          </button>
        </article>
      </div>
      <p v-if="!searchResults.length" class="hint">没有找到相关内容，换个关键词试试～</p>
    </section>

    <template v-else>
      <!-- 1. 主题策展 -->
      <section class="block">
        <div class="sec-head">
          <h2>🎬 场景策展</h2>
          <span class="sec-sub">按吃喝场景逛，绕开首页那 8 个美食分类</span>
        </div>
        <div class="curate">
          <aside class="cl-tabs">
            <button
              v-for="c in collections"
              :key="c.key"
              class="cl-tab"
              :class="{ on: activeKey === c.key }"
              @click="activeKey = c.key"
            >
              <span class="cl-icon">{{ c.icon }}</span>
              <span class="cl-name">{{ c.name }}</span>
              <span class="cl-num">{{ c.items.length }}</span>
            </button>
          </aside>

          <div v-if="activeCollection" class="cl-body">
            <div class="cl-banner" :style="{ background: activeCollection.bg }">
              <h3>{{ activeCollection.icon }} {{ activeCollection.name }}</h3>
              <p>{{ activeCollection.desc }}</p>
            </div>
            <div class="cl-grid">
              <article
                v-for="p in activeCollection.items"
                :key="'c' + p.id"
                class="cl-card"
                @click="openPost(p.id)"
              >
                <span class="cl-emoji" :style="{ background: catBg(p.category) }">{{ p.emoji }}</span>
                <div class="cl-info">
                  <h4>{{ p.title }}</h4>
                  <p>@{{ p.author }}</p>
                </div>
                <span class="cl-star">{{ avgRating(p.id) ? avgRating(p.id).toFixed(1) : '—' }}</span>
                <button class="cl-order" type="button" @click.stop="onOrder(p)">点单</button>
              </article>
            </div>
            <p v-if="!activeCollection.items.length" class="hint">这个专题暂时没有内容～</p>
          </div>
        </div>
      </section>

      <!-- 2. 今天吃什么 -->
      <section class="block">
        <div class="sec-head">
          <h2>🎲 今天吃什么</h2>
          <span class="sec-sub">纠结的时候，交给运气</span>
        </div>
        <div class="dice">
          <div class="dice-emoji" :class="{ rolling }">{{ lucky ? lucky.emoji : '🍽️' }}</div>
          <div class="dice-body">
            <template v-if="lucky">
              <h3>{{ lucky.title }}</h3>
              <p>{{ lucky.category }} · @{{ lucky.author }}</p>
            </template>
            <template v-else>
              <h3>点一下，帮你决定</h3>
              <p>从 {{ posts.length }} 道美食里随机抽一个</p>
            </template>
          </div>
          <div class="dice-actions">
            <button class="btn-ghost" type="button" @click="roll">🎲 {{ lucky ? '换一道' : '抽一个' }}</button>
            <button v-if="lucky" class="btn-main" type="button" @click="openPost(lucky.id)">看详情</button>
            <button v-if="lucky" class="btn-main" type="button" @click="onOrder(lucky)">立即点单</button>
          </div>
        </div>
      </section>

      <!-- 3. 宝藏挖掘 -->
      <section class="block">
        <div class="sec-head">
          <h2>💎 宝藏挖掘</h2>
          <span class="sec-sub">少人问津，但写得很认真</span>
        </div>
        <div class="tr-list">
          <article v-for="p in treasures" :key="'t' + p.id" class="tr-item" @click="openPost(p.id)">
            <span class="tr-emoji">{{ p.emoji }}</span>
            <div class="tr-body">
              <h4>{{ p.title }}<em class="tr-badge">冷门宝藏</em></h4>
              <p>{{ p.content }}</p>
            </div>
            <span class="tr-meta">💬 {{ reviewCount(p.id) }}</span>
          </article>
        </div>
        <p v-if="!treasures.length" class="hint">大家都挖过了，暂时没有冷门款～</p>
      </section>

      <!-- 4. 食客动态时间线 -->
      <section class="block">
        <div class="sec-head">
          <h2>🕒 食客动态</h2>
          <span class="sec-sub">刚刚，谁在吃什么</span>
        </div>
        <ul class="timeline">
          <li v-for="p in timeline" :key="'tl' + p.id" class="tl-item">
            <span class="tl-dot">{{ p.emoji }}</span>
            <div class="tl-card" @click="openPost(p.id)">
              <div class="tl-top">
                <b>@{{ p.author }}</b>
                <span class="tl-time">{{ fromNow(p.createdAt) }}</span>
              </div>
              <h4>{{ p.title }}</h4>
              <p>{{ p.content }}</p>
              <div class="tl-foot">
                <span class="tl-cat">{{ sceneOf(p) || p.category }}</span>
                <span>💬 {{ reviewCount(p.id) }}</span>
                <span>★ {{ avgRating(p.id) ? avgRating(p.id).toFixed(1) : '暂无' }}</span>
              </div>
            </div>
          </li>
        </ul>
      </section>

      <!-- 5. 值得关注 -->
      <section class="block">
        <div class="sec-head">
          <h2>⭐ 值得关注</h2>
          <span class="sec-sub">跟着会吃的人吃</span>
        </div>
        <div class="au-grid">
          <div v-for="a in authors" :key="a.name" class="au-card">
            <span class="au-avatar">{{ firstChar(a.name) }}</span>
            <div class="au-info">
              <h4>@{{ a.name }}</h4>
              <p>{{ a.posts }} 篇笔记 · 均分 {{ a.avg ? a.avg.toFixed(1) : '暂无' }}</p>
            </div>
            <button class="au-btn" :class="{ on: isFollowed(a.name) }" type="button" @click="toggleFollow(a.name)">
              {{ isFollowed(a.name) ? '已关注' : '+ 关注' }}
            </button>
          </div>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.discover{ position:relative; max-width:1040px; margin:0 auto; padding:24px 24px 72px; z-index:1; }

/* 漂浮装饰，与首页/排行榜保持一致 */
.bg-orbs{ position:absolute; inset:0; pointer-events:none; z-index:0; }
.bg-orbs span{ position:absolute; font-size:38px; opacity:.12; animation:orb 9s ease-in-out infinite; filter:blur(.3px); }
.o1{ left:3%; top:14%; } .o2{ left:84%; top:12%; animation-delay:.8s; }
.o3{ left:8%; top:72%; animation-delay:1.6s; } .o4{ left:88%; top:68%; animation-delay:2.4s; }
.o5{ left:46%; top:5%; animation-delay:3.2s; } .o6{ left:60%; top:84%; animation-delay:1.1s; }
.o7{ left:24%; top:42%; animation-delay:2.7s; font-size:50px; } .o8{ left:74%; top:46%; animation-delay:3.6s; }
@keyframes orb{ 0%,100%{ transform:translateY(0) rotate(-6deg); } 50%{ transform:translateY(-22px) rotate(8deg); } }

.topbar{ position:relative; z-index:2; display:flex; align-items:center; justify-content:space-between; margin-bottom:18px; }
.back, .mine{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted); padding:8px 14px;
  border-radius:11px; cursor:pointer; font-weight:600; transition:.2s; font-family:inherit; font-size:13.5px; }
.back:hover, .mine:hover{ border-color:var(--orange); color:var(--tomato); }
.top-right{ display:flex; gap:10px; }

/* ===== 头部：奶白卡片 + 左侧色带，和首页橙色渐变 Hero 区分 ===== */
.dhead{ position:relative; z-index:2; display:flex; align-items:flex-end; justify-content:space-between;
  gap:20px; flex-wrap:wrap; background:#fff; border:1.5px solid #f6ebe0; border-radius:22px;
  padding:22px 24px; box-shadow:0 14px 34px rgba(255,120,80,.10); overflow:hidden; }
.dhead::before{ content:""; position:absolute; left:0; top:0; bottom:0; width:6px;
  background:linear-gradient(180deg,var(--orange),var(--tomato)); }
.dhead-copy{ min-width:0; }
.badge{ display:inline-block; font-size:12px; font-weight:700; color:var(--tomato);
  background:#fff0ea; padding:4px 11px; border-radius:999px; margin-bottom:10px; }
.dhead h1{ font-size:27px; font-weight:800; letter-spacing:.4px; }
.dhead p{ margin-top:7px; font-size:13.5px; color:var(--muted); }

.dsearch{ display:flex; align-items:center; gap:9px; flex:1 1 300px; max-width:400px;
  background:#fdf6ee; border:1.5px solid #f0e2d4; border-radius:999px; padding:6px 8px 6px 16px; }
.dsearch .ic{ font-size:16px; opacity:.55; }
.dsearch input{ flex:1; min-width:0; border:0; outline:none; background:transparent;
  font-size:14px; color:var(--ink); font-family:inherit; padding:8px 0; }
.dsearch .clear{ border:0; background:#f0e6db; color:var(--muted); cursor:pointer;
  width:24px; height:24px; border-radius:50%; font-size:12px; line-height:1; flex-shrink:0; }

.loader-wrap{ position:relative; z-index:2; display:flex; justify-content:center; padding:60px 0; }
.spinner{ width:32px; height:32px; border-radius:50%; border:3px solid #f0e6db; border-top-color:var(--tomato); animation:spin .8s linear infinite; }
@keyframes spin{ to{ transform:rotate(360deg); } }

.block{ position:relative; z-index:2; margin-top:30px; animation:cardIn .45s backwards; }
@keyframes cardIn{ from{ opacity:0; transform:translateY(14px); } to{ opacity:1; transform:translateY(0); } }
.sec-head{ display:flex; align-items:baseline; gap:12px; flex-wrap:wrap; margin-bottom:14px; }
.sec-head h2{ font-size:20px; font-weight:800; }
.sec-sub{ font-size:12.5px; color:var(--muted); }
.hint{ color:var(--muted); padding:22px 0; text-align:center; font-size:13.5px; }

/* ===== 1. 主题策展 ===== */
.curate{ display:grid; grid-template-columns:196px 1fr; gap:16px; align-items:start; }
.cl-tabs{ display:flex; flex-direction:column; gap:8px; }
.cl-tab{ display:flex; align-items:center; gap:9px; text-align:left;
  border:1.5px solid #f0e2d4; background:#fff; color:#6f6055; font-family:inherit;
  padding:11px 13px; border-radius:15px; font-size:13.5px; font-weight:700; cursor:pointer; transition:.2s; }
.cl-tab:hover{ border-color:#ffc39a; color:var(--tomato); transform:translateX(2px); }
.cl-tab.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff;
  box-shadow:0 10px 20px rgba(255,90,60,.26); }
.cl-icon{ font-size:16px; }
.cl-name{ flex:1; }
.cl-num{ font-size:11px; font-weight:800; padding:1px 7px; border-radius:999px; background:#f6ece1; color:#a8917c; }
.cl-tab.on .cl-num{ background:rgba(255,255,255,.26); color:#fff; }

.cl-body{ min-width:0; }
.cl-banner{ border-radius:18px; padding:18px 20px; color:#fff; box-shadow:0 12px 28px rgba(90,40,30,.18); }
.cl-banner h3{ font-size:18px; font-weight:800; }
.cl-banner p{ margin-top:5px; font-size:12.5px; opacity:.9; }
.cl-grid{ display:grid; grid-template-columns:repeat(2,1fr); gap:12px; margin-top:12px; }
.cl-card{ display:flex; align-items:center; gap:11px; background:#fff; border:1.5px solid #f6ebe0;
  border-radius:16px; padding:11px 13px; cursor:pointer; transition:transform .2s, box-shadow .2s, border-color .2s; }
.cl-card:hover{ transform:translateY(-3px); box-shadow:0 14px 28px rgba(255,90,60,.16); border-color:#ffd9bf; }
.cl-emoji{ width:42px; height:42px; flex-shrink:0; border-radius:13px; display:flex; align-items:center;
  justify-content:center; font-size:23px; box-shadow:inset 0 0 0 1px rgba(255,255,255,.7); }
.cl-info{ flex:1; min-width:0; }
.cl-info h4{ font-size:14px; line-height:1.35; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.cl-info p{ font-size:11.5px; color:var(--muted); margin-top:3px; }
.cl-star{ font-size:12px; font-weight:800; color:var(--tomato); flex-shrink:0; }
.cl-order{ flex-shrink:0; border:1.5px solid #f0e2d4; background:#fff; color:var(--muted);
  padding:6px 11px; border-radius:10px; font-size:12px; font-weight:700; cursor:pointer; transition:.2s; font-family:inherit; }
.cl-order:hover{ border-color:var(--orange); color:var(--tomato); }
@media (max-width:820px){
  .curate{ grid-template-columns:1fr; }
  .cl-tabs{ flex-direction:row; flex-wrap:wrap; }
  .cl-tab{ flex:1 1 140px; }
}
@media (max-width:520px){ .cl-grid{ grid-template-columns:1fr; } }

/* ===== 2. 今天吃什么 ===== */
.dice{ display:flex; align-items:center; gap:18px; flex-wrap:wrap;
  background:#fff; border:1.5px dashed #ffd0ba; border-radius:22px; padding:20px 22px;
  box-shadow:0 12px 30px rgba(255,120,80,.09); }
.dice-emoji{ width:76px; height:76px; flex-shrink:0; border-radius:22px; display:flex; align-items:center;
  justify-content:center; font-size:42px; background:linear-gradient(140deg,#fff5e8,#ffdfba); }
.dice-emoji.rolling{ animation:diceShake .3s ease-in-out infinite; }
@keyframes diceShake{ 0%,100%{ transform:rotate(-7deg) scale(1); } 50%{ transform:rotate(7deg) scale(1.06); } }
.dice-body{ flex:1; min-width:150px; }
.dice-body h3{ font-size:18px; font-weight:800; }
.dice-body p{ margin-top:5px; font-size:12.5px; color:var(--muted); }
.dice-actions{ display:flex; gap:9px; flex-wrap:wrap; }
.btn-ghost{ border:1.5px solid #f0e2d4; background:#fff; color:var(--muted); padding:10px 16px;
  border-radius:12px; font-size:13px; font-weight:700; cursor:pointer; transition:.2s; font-family:inherit; }
.btn-ghost:hover{ border-color:var(--orange); color:var(--tomato); }
.btn-main{ border:0; color:#fff; padding:10px 16px; border-radius:12px; font-size:13px; font-weight:700;
  cursor:pointer; background:linear-gradient(120deg,var(--orange),var(--tomato));
  box-shadow:0 8px 18px rgba(255,90,60,.26); transition:.2s; font-family:inherit; }
.btn-main:hover{ filter:brightness(1.05); }

/* ===== 3. 宝藏挖掘 ===== */
.tr-list{ display:flex; flex-direction:column; gap:11px; }
.tr-item{ display:flex; align-items:flex-start; gap:13px; background:#fff; border:1.5px solid #f6ebe0;
  border-radius:16px; padding:14px 16px; cursor:pointer; transition:transform .2s, box-shadow .2s, border-color .2s; }
.tr-item:hover{ transform:translateY(-3px); box-shadow:0 14px 28px rgba(255,90,60,.15); border-color:#ffd9bf; }
.tr-emoji{ font-size:28px; flex-shrink:0; }
.tr-body{ flex:1; min-width:0; }
.tr-body h4{ font-size:15px; display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.tr-badge{ font-style:normal; font-size:11px; font-weight:700; color:#8a6b1f; background:#fff3d0;
  padding:2px 8px; border-radius:8px; }
.tr-body p{ margin-top:5px; font-size:13px; color:var(--muted); line-height:1.6;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.tr-meta{ font-size:12px; color:#c4b3a4; flex-shrink:0; }

/* ===== 4. 食客动态时间线 ===== */
.timeline{ list-style:none; position:relative; padding-left:26px; }
.timeline::before{ content:""; position:absolute; left:9px; top:8px; bottom:8px; width:2px;
  background:linear-gradient(180deg,#ffd0ba,#ffe9d6); border-radius:2px; }
.tl-item{ position:relative; margin-bottom:12px; }
.tl-dot{ position:absolute; left:-26px; top:16px; width:20px; height:20px; border-radius:50%;
  display:flex; align-items:center; justify-content:center; font-size:11px; background:#fff;
  border:2px solid #ffd0ba; z-index:2; }
.tl-card{ background:#fff; border:1.5px solid #f6ebe0; border-radius:16px; padding:13px 16px;
  cursor:pointer; transition:transform .2s, box-shadow .2s, border-color .2s; }
.tl-card:hover{ transform:translateX(3px); box-shadow:0 12px 26px rgba(255,90,60,.14); border-color:#ffd9bf; }
.tl-top{ display:flex; align-items:center; justify-content:space-between; gap:10px; }
.tl-top b{ font-size:13.5px; }
.tl-time{ font-size:11.5px; color:#c4b3a4; }
.tl-card h4{ font-size:15px; margin-top:6px; }
.tl-card p{ margin-top:5px; font-size:12.8px; color:var(--muted); line-height:1.6;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.tl-foot{ display:flex; align-items:center; gap:12px; margin-top:9px; font-size:11.5px; color:#bba; }
.tl-cat{ color:var(--tomato); background:#fff0ea; padding:2px 9px; border-radius:8px; font-weight:700; }

/* ===== 5. 值得关注 ===== */
.au-grid{ display:grid; grid-template-columns:repeat(3,1fr); gap:12px; }
.au-card{ display:flex; align-items:center; gap:11px; background:#fff; border:1.5px solid #f6ebe0;
  border-radius:16px; padding:13px 14px; transition:transform .2s, box-shadow .2s; }
.au-card:hover{ transform:translateY(-3px); box-shadow:0 14px 28px rgba(255,90,60,.13); }
.au-avatar{ width:38px; height:38px; flex-shrink:0; border-radius:50%; display:flex; align-items:center;
  justify-content:center; font-size:15px; font-weight:800; color:#8a4b22;
  background:linear-gradient(140deg,#ffe0c8,#ffbe90); }
.au-info{ flex:1; min-width:0; }
.au-info h4{ font-size:13.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.au-info p{ font-size:11.5px; color:var(--muted); margin-top:3px; }
.au-btn{ flex-shrink:0; border:1.5px solid #f0e2d4; background:#fff; color:var(--muted);
  padding:6px 11px; border-radius:999px; font-size:12px; font-weight:700; cursor:pointer; transition:.2s; font-family:inherit; }
.au-btn:hover{ border-color:var(--orange); color:var(--tomato); }
.au-btn.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }
@media (max-width:820px){ .au-grid{ grid-template-columns:repeat(2,1fr); } }
@media (max-width:520px){ .au-grid{ grid-template-columns:1fr; } }

/* ===== 搜索结果 ===== */
.result-list{ display:flex; flex-direction:column; gap:11px; }
.rs-item{ display:flex; align-items:center; gap:13px; background:#fff; border:1.5px solid #f6ebe0;
  border-radius:16px; padding:13px 16px; cursor:pointer; transition:transform .2s, box-shadow .2s, border-color .2s; }
.rs-item:hover{ transform:translateY(-3px); box-shadow:0 14px 28px rgba(255,90,60,.15); border-color:#ffd9bf; }
.rs-emoji{ width:46px; height:46px; flex-shrink:0; border-radius:14px; display:flex; align-items:center;
  justify-content:center; font-size:25px; box-shadow:inset 0 0 0 1px rgba(255,255,255,.7); }
.rs-body{ flex:1; min-width:0; }
.rs-body h4{ font-size:15px; }
.rs-body p{ margin-top:4px; font-size:12.5px; color:var(--muted); line-height:1.6;
  display:-webkit-box; -webkit-line-clamp:1; -webkit-box-orient:vertical; overflow:hidden; }
.rs-meta{ display:flex; align-items:center; gap:11px; margin-top:6px; font-size:11.5px; color:#bba; }
.rs-cat{ color:var(--tomato); background:#fff0ea; padding:2px 9px; border-radius:8px; font-weight:700; }
.rs-fav{ flex-shrink:0; width:30px; height:30px; border-radius:50%; border:0; cursor:pointer;
  font-size:14px; color:#bda995; background:#f7efe7; transition:.2s; }
.rs-fav.on{ color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato)); }

@media (max-width:760px){
  .dhead{ align-items:flex-start; }
  .dsearch{ max-width:none; width:100%; }
}
</style>
