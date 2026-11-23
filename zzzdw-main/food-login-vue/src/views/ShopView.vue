<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getToken } from '../composables/useAuth.js'
import { useToast } from '../composables/useToast.js'
import { catBg } from '../data/categories.js'
import ImgCarousel from '../components/ImgCarousel.vue'

const router = useRouter()
const { toast } = useToast()

const API = '/api'

const loading = ref(false)
const saving = ref(false)
const acting = ref(null)   // 正在上/下架的菜品 id，避免重复点击
const opened = ref(false)
const shop = ref(null)
const posts = ref([])
const editing = ref(false)

// 开店 / 改资料表单
const form = ref({
  shopName: '', emoji: '🏠', description: '', district: '', phone: '',
  status: 'active', openTime: '09:00', closeTime: '21:30'
})

// 可选图标与商圈（商圈与数据库现有数据保持一致）
const EMOJIS = ['🍜', '🍲', '🍥', '🥢', '🥟', '🔥', '🍢', '🦪', '🍻', '🍗', '🥗', '🍔', '🥑', '🍰', '☕', '🏠']
const DISTRICTS = ['老城区', '科技园', '五道口', '万象城', '大学城', '南锣鼓巷', '三里屯', '滨江道']

const approvedCount = computed(() => posts.value.filter(p => p.status === 'approved').length)
const pendingCount = computed(() => posts.value.filter(p => p.status === 'pending').length)

// 店铺实时营业状态：休息中 / 未开始 / 即将打烊 / 营业中
const shopOpen = computed(() => {
  if (!shop.value) return null
  if (shop.value.status === 'closed') return { key: 'closed', label: '休息中', cls: 'off' }
  const ot = shop.value.openTime, ct = shop.value.closeTime
  if (!ot || !ct) return { key: 'open', label: '营业中', cls: 'on' }
  const [oh, om] = ot.split(':').map(Number)
  const [ch, cm] = ct.split(':').map(Number)
  const t = new Date().getHours() * 60 + new Date().getMinutes()
  const o = oh * 60 + om, c = ch * 60 + cm
  if (t < o) return { key: 'soon', label: '未开始', cls: 'off' }
  if (t >= c) return { key: 'closed', label: '已打烊', cls: 'off' }
  if (c - t <= 60) return { key: 'closing', label: '即将打烊', cls: 'warn' }
  return { key: 'open', label: '营业中', cls: 'on' }
})

function authHeaders(extra = {}) {
  return { ...extra, Authorization: `Bearer ${getToken()}` }
}

async function load(silent = false) {
  if (!silent) loading.value = true
  try {
    const r = await fetch(`${API}/shop`, { headers: authHeaders() })
    if (r.status === 401) { router.push('/login'); return }
    const data = await r.json().catch(() => ({}))
    if (!r.ok) throw new Error(data.message || '加载店铺失败')
    opened.value = !!data.opened
    shop.value = data.shop || null
    posts.value = data.posts || []
  } catch (e) {
    toast(e.message || '加载店铺失败', 'error')
  } finally {
    loading.value = false
  }
}

// 店主上架 / 下架自己的菜品：approved <-> off（待审核/已驳回不在这里动）
async function toggleShelf(p, target) {
  acting.value = p.id
  try {
    const r = await fetch(`${API}/shop/posts/${p.id}`, {
      method: 'PATCH',
      headers: authHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({ status: target })
    })
    if (r.status === 401) { router.push('/login'); return }
    const data = await r.json().catch(() => ({}))
    if (!r.ok) throw new Error(data.message || '操作失败')
    p.status = data.status || target
    toast(target === 'off' ? '已下架，食客暂时看不到了' : '已重新上架', 'success')
    await load(true)   // 统计要跟着变，静默刷新避免整页闪白
  } catch (e) {
    toast(e.message || '操作失败', 'error')
  } finally {
    acting.value = null
  }
}

// 已开店：进入编辑态并回填现有资料
function startEdit() {
  const s = shop.value
  form.value = {
    shopName: s.shopName || '',
    emoji: s.emoji || '🏠',
    description: s.description || '',
    district: s.district || '',
    phone: s.phone || '',
    status: s.status || 'active',
    openTime: s.openTime || '09:00',
    closeTime: s.closeTime || '21:30'
  }
  editing.value = true
}

// 未开店：打开同一表单，填写后即为开店
function startOpen() {
  form.value = {
    shopName: '', emoji: '🏠', description: '', district: '', phone: '',
    status: 'active', openTime: '09:00', closeTime: '21:30'
  }
  editing.value = true
}

function cancelEdit() {
  editing.value = false
}

async function save() {
  if (!form.value.shopName.trim()) { toast('店铺名称不能为空', 'error'); return }
  saving.value = true
  try {
    const r = await fetch(`${API}/shop`, {
      method: 'PUT',
      headers: authHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({
        shopName: form.value.shopName.trim(),
        emoji: form.value.emoji,
        description: form.value.description.trim(),
        district: form.value.district,
        phone: form.value.phone.trim(),
        status: form.value.status,
        openTime: form.value.openTime || '',
        closeTime: form.value.closeTime || ''
      })
    })
    const data = await r.json().catch(() => ({}))
    if (r.status === 401) { router.push('/login'); return }
    if (!r.ok) throw new Error(data.message || '保存失败')
    toast(opened.value ? '店铺资料已更新' : '开店成功，去发布第一道菜吧！', 'success')
    editing.value = false
    await load()
  } catch (e) {
    toast(e.message || '保存失败', 'error')
  } finally {
    saving.value = false
  }
}

function openPost(id) { router.push(`/post/${id}`) }
function dateStr(t) {
  if (!t) return '—'
  const d = new Date(t)
  return Number.isFinite(d.getTime()) ? `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` : '—'
}
function stars(n) {
  const f = Math.round(Number(n) || 0)
  return '★'.repeat(f) + '☆'.repeat(Math.max(0, 5 - f))
}
function statusText(s) {
  return { approved: '已上架', off: '已下架', pending: '待审核', rejected: '已驳回' }[s] || s
}

onMounted(load)
</script>

<template>
  <div class="shop">
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>

    <div class="topbar">
      <button class="back" @click="router.push('/profile')">← 返回我的</button>
      <button v-if="opened && !editing" class="ghost" @click="startEdit">✏️ 编辑资料</button>
    </div>

    <p v-if="loading" class="loader-wrap"><span class="spinner"></span></p>

    <template v-else>
      <!-- ===== 店铺主页 ===== -->
      <template v-if="opened && !editing">
        <section class="hero">
          <div class="s-emoji">{{ shop.emoji || '🏠' }}</div>
          <div class="s-who">
          <div class="title-row">
            <h1>{{ shop.shopName }}</h1>
            <span v-if="shopOpen" class="pill" :class="shopOpen.cls">
              <i class="pill-dot"></i>{{ shopOpen.label }}
            </span>
          </div>
            <p class="desc">{{ shop.description || '这家店还没有写简介，点右上角编辑补充一下吧～' }}</p>
            <div class="meta">
              <span v-if="shop.district">📍 {{ shop.district }}</span>
              <span v-if="shop.openTime && shop.closeTime">🕐 {{ shop.openTime }}–{{ shop.closeTime }}</span>
              <span v-if="shop.phone">📞 {{ shop.phone }}</span>
              <span>🗓 开店于 {{ dateStr(shop.createTime) }}</span>
              <span v-if="shop.ownerName">👤 店主 @{{ shop.ownerName }}</span>
            </div>
          </div>
        </section>

        <div class="stats">
          <div class="stat"><b>{{ shop.postCount ?? 0 }}</b><span>在售菜品</span></div>
          <div class="stat"><b>{{ (shop.avgRating ?? 0).toFixed ? (shop.avgRating ?? 0).toFixed(1) : shop.avgRating }}</b><span>店铺均分</span></div>
          <div class="stat"><b>{{ shop.reviewCount ?? 0 }}</b><span>累计点评</span></div>
          <div class="stat"><b>{{ shop.favoriteCount ?? 0 }}</b><span>累计收藏</span></div>
        </div>

        <div class="actions">
          <button class="btn" @click="router.push('/')">➕ 发布新菜品</button>
          <button class="btn ghost-line" @click="router.push('/ranking')">🏆 看看排名</button>
        </div>

        <div class="sec-head">
          <h2>店内菜品</h2>
          <span class="sec-sub">
            共 {{ posts.length }} 道
            <template v-if="pendingCount"> · 待审核 {{ pendingCount }}</template>
          </span>
        </div>

        <div v-if="posts.length" class="grid">
          <article v-for="p in posts" :key="p.id" class="card" @click="openPost(p.id)">
            <div class="c-cover" :style="{ background: catBg(p.category) }">
              <!-- 多图轮播：懒加载 + 骨架屏 + 实拍图浅水印 -->
              <ImgCarousel :post="p" />
            </div>
            <div class="c-body">
              <div class="c-top">
                <span class="tag">{{ p.category }}</span>
                <span class="c-status" :class="p.status">{{ statusText(p.status) }}</span>
              </div>
              <h3>{{ p.title }}</h3>
              <p class="excerpt">{{ p.content }}</p>
              <div class="c-foot">
                <span class="c-stars">{{ stars(p.rating) }}</span>
                <span>{{ Number(p.rating || 0).toFixed(1) }} · 💬 {{ p.reviewCount ?? 0 }} · ★ {{ p.favoriteCount ?? 0 }}</span>
              </div>
              <!-- 店主自管：已上架可下架，已下架可重新上架；待审核/已驳回交给管理员 -->
              <div v-if="p.status === 'approved' || p.status === 'off'" class="c-act">
                <button :disabled="acting === p.id"
                        :class="{ re: p.status === 'off' }"
                        @click.stop="toggleShelf(p, p.status === 'off' ? 'approved' : 'off')">
                  {{ acting === p.id ? '处理中…' : (p.status === 'off' ? '重新上架' : '下架') }}
                </button>
              </div>
            </div>
          </article>
        </div>
        <p v-else class="hint">店里还空着，去广场点「＋」把招牌菜上架吧～</p>
      </template>

      <!-- ===== 开店 / 编辑资料 ===== -->
      <section v-else class="panel">
        <header class="p-head">
          <h1>{{ opened ? '编辑店铺资料' : '开一家自己的店' }}</h1>
          <p>{{ opened ? '店名改完，店里所有菜品卡片会同步显示新名字。' : '填好下面几项就能开店，之后发布的菜品会自动挂在店里。' }}</p>
        </header>

        <div class="field">
          <label>店铺名称 <em>必填，全局唯一</em></label>
          <input v-model="form.shopName" class="input" maxlength="60" placeholder="例如：老张牛肉面" />
        </div>

        <div class="field">
          <label>店铺图标</label>
          <div class="picker">
            <button v-for="e in EMOJIS" :key="e" class="pick"
                    :class="{ on: form.emoji === e }" @click="form.emoji = e">{{ e }}</button>
          </div>
        </div>

        <div class="field">
          <label>店铺简介 <em>一句话说清招牌</em></label>
          <textarea v-model="form.description" class="input area" maxlength="255" rows="3"
                    placeholder="例如：三十年老汤牛肉面，手工拉面现煮"></textarea>
        </div>

        <div class="field-row">
          <div class="field">
            <label>所在商圈</label>
            <select v-model="form.district" class="input">
              <option value="">暂不填写</option>
              <option v-for="d in DISTRICTS" :key="d" :value="d">{{ d }}</option>
            </select>
          </div>
          <div class="field">
            <label>联系电话</label>
            <input v-model="form.phone" class="input" maxlength="32" placeholder="例如：400-1001-001" />
          </div>
          <div class="field">
            <label>营业状态</label>
            <select v-model="form.status" class="input">
              <option value="active">营业中</option>
              <option value="closed">休息中</option>
            </select>
          </div>
        </div>

        <div class="field-row">
          <div class="field">
            <label>营业开始 <em>留空则不展示营业时间</em></label>
            <input v-model="form.openTime" type="time" class="input" />
          </div>
          <div class="field">
            <label>营业结束</label>
            <input v-model="form.closeTime" type="time" class="input" />
          </div>
        </div>

        <div class="p-foot">
          <button class="btn" :disabled="saving" @click="save">
            {{ saving ? '保存中…' : (opened ? '保存修改' : '立即开店') }}
          </button>
          <button class="btn ghost-line" :disabled="saving" @click="cancelEdit">
            {{ opened ? '取消' : '先不开' }}
          </button>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.shop{ position:relative; max-width:1000px; margin:0 auto; padding:24px 24px 90px; z-index:1; }

/* 漂浮装饰，与首页 / 我的页面统一 */
.bg-orbs{ position:absolute; inset:0; pointer-events:none; z-index:0; }
.bg-orbs span{ position:absolute; font-size:38px; opacity:.14; animation:orb 9s ease-in-out infinite; filter:blur(.3px); }
.o1{ left:4%;  top:12%; } .o2{ left:82%; top:10%; animation-delay:.8s; }
.o3{ left:10%; top:70%; animation-delay:1.6s; } .o4{ left:88%; top:66%; animation-delay:2.4s; }
.o5{ left:44%; top:6%;  animation-delay:3.2s; } .o6{ left:62%; top:82%; animation-delay:1.1s; }
.o7{ left:26%; top:40%; animation-delay:2.7s; font-size:50px; } .o8{ left:72%; top:44%; animation-delay:3.6s; }
@keyframes orb{ 0%,100%{ transform:translateY(0) rotate(-6deg); } 50%{ transform:translateY(-22px) rotate(8deg); } }

.topbar{ position:relative; z-index:2; display:flex; align-items:center; justify-content:space-between; margin-bottom:18px; gap:10px; }
.back, .ghost{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:8px 14px; border-radius:11px; cursor:pointer; font-weight:600; transition:.2s; font-family:inherit; }
.back:hover, .ghost:hover{ border-color:var(--orange); color:var(--tomato); }

.loader-wrap{ position:relative; z-index:2; display:flex; justify-content:center; padding:60px 0; }
.spinner{ width:32px; height:32px; border-radius:50%; border:3px solid #f0e6db; border-top-color:var(--tomato); animation:spin .8s linear infinite; }
@keyframes spin{ to{ transform:rotate(360deg); } }

/* 店铺信息卡：沿用「我的」页面的渐变卡 */
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
.pill.warn{ background:rgba(255,255,255,.9); color:#b07010; }
.pill-dot{ width:7px; height:7px; border-radius:50%; display:inline-block; margin-right:5px; background:currentColor; }
.desc{ margin-top:7px; font-size:13.5px; line-height:1.6; opacity:.94; }
.meta{ display:flex; flex-wrap:wrap; gap:14px; margin-top:10px; font-size:12.5px; opacity:.9; }

/* 四宫格统计 */
.stats{ position:relative; z-index:2; display:grid; grid-template-columns:repeat(4,1fr); gap:14px; margin-top:16px; }
.stat{ background:#fff; border-radius:16px; padding:16px 14px; text-align:center;
  box-shadow:0 8px 20px rgba(255,90,60,.08); border:1px solid #f6ede2; }
.stat b{ display:block; font-size:24px; font-weight:800; color:var(--tomato); line-height:1.15; }
.stat span{ font-size:12.5px; color:var(--muted); }

.actions{ position:relative; z-index:2; display:flex; gap:10px; flex-wrap:wrap; margin-top:16px; }
.btn{ border:0; border-radius:12px; padding:11px 20px; font-weight:700; font-size:14px; cursor:pointer; color:#fff;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 8px 18px rgba(255,90,60,.28);
  transition:.2s; font-family:inherit; }
.btn:hover{ filter:brightness(1.05); }
.btn:disabled{ opacity:.55; cursor:not-allowed; }
.btn.ghost-line{ background:#fff; color:var(--tomato); border:1.5px solid #ffd9b0; box-shadow:none; }
.btn.ghost-line:hover{ background:#fff7f2; }

.sec-head{ position:relative; z-index:2; display:flex; align-items:baseline; gap:10px; margin:26px 0 14px; }
.sec-head h2{ font-size:18px; font-weight:800; }
.sec-sub{ font-size:12.5px; color:var(--muted); }

.grid{ position:relative; z-index:2; display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.card{ background:#fff; border-radius:16px; overflow:hidden; cursor:pointer;
  box-shadow:0 8px 20px rgba(0,0,0,.05); transition:transform .2s, box-shadow .2s;
  animation:cardIn .45s backwards; display:flex; flex-direction:column; }
.card:hover{ transform:translateY(-4px); box-shadow:0 14px 28px rgba(255,90,60,.18); }
@keyframes cardIn{ from{ opacity:0; transform:translateY(14px); } to{ opacity:1; transform:translateY(0); } }
.c-cover{ position:relative; width:100%; aspect-ratio:4/3; overflow:hidden; display:flex; align-items:center; justify-content:center; }
.c-cover img{ width:100%; height:100%; object-fit:cover; display:block; transition:transform .45s; }
.card:hover .c-cover img{ transform:scale(1.08); }
.c-fallback{ position:absolute; inset:0; display:flex; align-items:center; justify-content:center; }
.c-glow{ position:absolute; width:140px; height:140px; border-radius:50%;
  background:radial-gradient(circle,rgba(255,255,255,.75),rgba(255,255,255,0) 70%); }
.c-emoji{ position:relative; font-size:52px; padding:16px; border-radius:50%;
  background:rgba(255,255,255,.55); box-shadow:0 10px 24px rgba(160,90,50,.18), inset 0 0 0 1.5px rgba(255,255,255,.7);
  transition:transform .35s; }
.card:hover .c-emoji{ transform:scale(1.1) rotate(-5deg); }
.c-body{ padding:14px 18px 18px; }
.c-top{ display:flex; align-items:center; justify-content:space-between; gap:8px; margin-bottom:8px; }
.tag{ display:inline-block; font-size:11.5px; color:var(--tomato); background:#fff0ea; padding:3px 9px; border-radius:10px; }
.c-status{ font-size:11px; font-weight:700; padding:3px 8px; border-radius:999px; white-space:nowrap; }
.c-status.approved{ background:#e9f7ee; color:var(--ok); }
.c-status.off{ background:#f1ece5; color:var(--muted); }
.c-status.pending{ background:#fff1e0; color:#c8771a; }
.c-status.rejected{ background:#fde8e8; color:var(--err); }
.card h3{ font-size:16px; margin-bottom:6px; }
.excerpt{ font-size:13px; color:var(--muted); line-height:1.5;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.c-foot{ display:flex; flex-direction:column; gap:2px; margin-top:10px; font-size:12px; color:var(--muted); }
.c-act{ margin-top:11px; padding-top:10px; border-top:1px dashed #f0e6db; }
.c-act button{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted); border-radius:9px;
  padding:5px 12px; font-size:12px; font-weight:600; cursor:pointer; font-family:inherit; transition:.18s; }
.c-act button:hover:not(:disabled){ border-color:var(--tomato); color:var(--tomato); }
.c-act button.re{ border-color:#ffd9b0; color:var(--tomato); background:#fff7f2; }
.c-act button:disabled{ opacity:.55; cursor:not-allowed; }
.c-stars{ color:#f5a623; letter-spacing:1px; }

.hint{ position:relative; z-index:2; color:var(--muted); padding:34px 0; text-align:center; font-size:14px; }

/* 表单 */
.panel{ position:relative; z-index:2; background:#fff; border-radius:20px; padding:24px 26px;
  box-shadow:0 14px 34px rgba(255,90,60,.10); border:1px solid #f6ede2; max-width:720px; }
.p-head h1{ font-size:21px; font-weight:800; }
.p-head p{ margin-top:6px; margin-bottom:20px; font-size:13.5px; color:var(--muted); line-height:1.6; }
.field{ margin-bottom:16px; }
.field label{ display:block; font-size:13px; font-weight:700; margin-bottom:7px; }
.field label em{ font-style:normal; font-weight:500; color:var(--muted); font-size:12px; margin-left:6px; }
.input{ width:100%; padding:10px 12px; border:1.5px solid #ecdfd2; border-radius:11px;
  font-size:14px; outline:none; font-family:inherit; background:#fff; color:var(--ink); }
.input:focus{ border-color:var(--orange); }
.area{ resize:vertical; line-height:1.6; }
.field-row{ display:grid; grid-template-columns:repeat(3,1fr); gap:14px; }
.picker{ display:flex; flex-wrap:wrap; gap:8px; }
.pick{ width:42px; height:42px; border-radius:12px; border:1.5px solid #ecdfd2; background:#fff;
  font-size:21px; cursor:pointer; transition:.18s; }
.pick:hover{ border-color:var(--orange); transform:translateY(-2px); }
.pick.on{ border-color:transparent; background:linear-gradient(120deg,var(--orange),var(--tomato));
  box-shadow:0 8px 16px rgba(255,90,60,.28); }
.p-foot{ display:flex; gap:10px; margin-top:22px; }

@media (max-width:760px){
  .grid{ grid-template-columns:repeat(2,1fr); }
  .stats{ grid-template-columns:repeat(2,1fr); }
  .field-row{ grid-template-columns:1fr; }
}
@media (max-width:480px){
  .grid{ grid-template-columns:1fr; }
}
</style>
