<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

// 「食光城」美食地图：8 个区 + 24 家店铺（前端示例数据，便于离线体验）
const districts = [
  { key: '面食控', name: '老城面巷', x: 30, y: 20, w: 330, h: 140, fill: '#ffe3d3' },
  { key: '日料局', name: '海湾日料', x: 400, y: 20, w: 330, h: 140, fill: '#d6ecff' },
  { key: '汉堡炸鸡', name: '炸鸡广场', x: 30, y: 180, w: 330, h: 140, fill: '#ffe9c2' },
  { key: '轻食沙拉', name: '轻食绿洲', x: 400, y: 180, w: 330, h: 140, fill: '#d9f3df' },
  { key: '甜品时间', name: '甜心巷', x: 30, y: 340, w: 330, h: 140, fill: '#ffd9ec' },
  { key: '咖啡馆', name: '咖啡街角', x: 400, y: 340, w: 330, h: 140, fill: '#e7ddff' },
  { key: '烧烤夜宵', name: '夜宵烧烤', x: 30, y: 500, w: 330, h: 140, fill: '#f7e2c8' },
  { key: '火锅江湖', name: '火锅江湖', x: 400, y: 500, w: 330, h: 140, fill: '#d5eff2' }
]

const spots = [
  { id: 1, name: '陈记拉面', emoji: '🍜', district: '老城面巷', cat: '面食控', x: 150, y: 78, rating: 4.8, dish: '招牌红烧牛肉面', address: '老城面巷 12 号', desc: '三代人守着一锅牛骨汤，汤头浓到挂壁，面码给得毫不手软。' },
  { id: 2, name: '巷子刀削', emoji: '🍲', district: '老城面巷', cat: '面食控', x: 250, y: 112, rating: 4.6, dish: '酸汤刀削面', address: '老城面巷 27 号', desc: '师傅现削现煮，酸汤里藏着十几种香料，酸得人精神一振。' },
  { id: 3, name: '阿婆馄饨', emoji: '🥟', district: '老城面巷', cat: '面食控', x: 165, y: 135, rating: 4.7, dish: '荠菜鲜肉馄饨', address: '老城面巷 5 号', desc: '皮薄如纸，一口一个，汤里漂着葱花和猪油香。' },

  { id: 4, name: '鲸吞寿司', emoji: '🍣', district: '海湾日料', cat: '日料局', x: 470, y: 78, rating: 4.9, dish: '三文鱼大腹', address: '海湾日料 8 号', desc: '鱼生每天空运，师傅捏了二十年醋饭，入口先暖后化。' },
  { id: 5, name: '海雾居酒屋', emoji: '🍶', district: '海湾日料', cat: '日料局', x: 600, y: 112, rating: 4.5, dish: '炭烤鳗鱼', address: '海湾日料 19 号', desc: '下班来一杯清酒，配炙烤鳗鱼，油脂在舌尖跳舞。' },
  { id: 6, name: '一兰拉面', emoji: '🍥', district: '海湾日料', cat: '日料局', x: 540, y: 135, rating: 4.6, dish: '豚骨拉面', address: '海湾日料 3 号', desc: '浓白汤底熬足十二小时，叉烧入口即化。' },

  { id: 7, name: '脆皮叔叔', emoji: '🍗', district: '炸鸡广场', cat: '汉堡炸鸡', x: 150, y: 228, rating: 4.4, dish: '韩式炸鸡', address: '炸鸡广场 6 号', desc: '外脆里嫩，甜辣酱是灵魂，配啤酒绝配。' },
  { id: 8, name: '怒汉堡', emoji: '🍔', district: '炸鸡广场', cat: '汉堡炸鸡', x: 250, y: 262, rating: 4.5, dish: '双层芝士牛堡', address: '炸鸡广场 14 号', desc: '肉饼现煎，芝士拉丝能拉半米，一口下去超满足。' },
  { id: 9, name: '薯条星人', emoji: '🍟', district: '炸鸡广场', cat: '汉堡炸鸡', x: 165, y: 300, rating: 4.3, dish: '松露薯条', address: '炸鸡广场 2 号', desc: '现切薯条撒松露盐，香到舔手指。' },

  { id: 10, name: '绿野仙踪', emoji: '🥗', district: '轻食绿洲', cat: '轻食沙拉', x: 470, y: 228, rating: 4.6, dish: '牛油果鸡胸沙拉', address: '轻食绿洲 11 号', desc: '酱汁自调，低卡也能吃到满足，摆盘像幅画。' },
  { id: 11, name: '果昔工坊', emoji: '🥤', district: '轻食绿洲', cat: '轻食沙拉', x: 600, y: 262, rating: 4.4, dish: '羽衣甘蓝果昔', address: '轻食绿洲 21 号', desc: '一杯下肚，蔬菜配额轻松达标，清爽不齁。' },
  { id: 18, name: '藜麦小厨', emoji: '🥙', district: '轻食绿洲', cat: '轻食沙拉', x: 530, y: 300, rating: 4.3, dish: '藜麦能量碗', address: '轻食绿洲 5 号', desc: '蛋白碳水均衡，健身党最爱，吃完很有干劲。' },

  { id: 12, name: '糖垛', emoji: '🍰', district: '甜心巷', cat: '甜品时间', x: 150, y: 378, rating: 4.8, dish: '海盐芝士蛋糕', address: '甜心巷 9 号', desc: '咸甜交织，吃两块也不腻，是甜品控的朝圣地。' },
  { id: 13, name: '团子铺', emoji: '🍡', district: '甜心巷', cat: '甜品时间', x: 250, y: 412, rating: 4.7, dish: '抹茶大福', address: '甜心巷 16 号', desc: '手作糯米皮，咬开爆浆抹茶，温柔到犯规。' },
  { id: 14, name: '可可星球', emoji: '🍫', district: '甜心巷', cat: '甜品时间', x: 165, y: 438, rating: 4.5, dish: '熔岩巧克力', address: '甜心巷 4 号', desc: '现烤流心，配香草冰淇淋，冷热交错很上头。' },

  { id: 15, name: '晨光咖啡', emoji: '☕', district: '咖啡街角', cat: '咖啡馆', x: 470, y: 378, rating: 4.7, dish: '燕麦拿铁', address: '咖啡街角 7 号', desc: '豆子每周烘焙，奶泡绵密如云，坐一下午都不腻。' },
  { id: 16, name: '慢煮茶铺', emoji: '🍵', district: '咖啡街角', cat: '咖啡馆', x: 600, y: 412, rating: 4.4, dish: '焙茶拿铁', address: '咖啡街角 22 号', desc: '焙茶香气沉稳，午后一杯刚刚好。' },
  { id: 17, name: '焦糖可读', emoji: '🍮', district: '咖啡街角', cat: '咖啡馆', x: 540, y: 438, rating: 4.6, dish: '焦糖玛奇朵', address: '咖啡街角 13 号', desc: '靠窗位适合看书，WiFi 也很稳，续杯无压力。' },

  { id: 19, name: '炭火小屋', emoji: '🍢', district: '夜宵烧烤', cat: '烧烤夜宵', x: 150, y: 558, rating: 4.7, dish: '炭烤厚切五花', address: '夜宵烧烤 3 号', desc: '肥瘦相间的五花在炭火上滋滋冒油，边缘焦脆，生菜一卷就是快乐。' },
  { id: 20, name: '老李烤串', emoji: '🍖', district: '夜宵烧烤', cat: '烧烤夜宵', x: 250, y: 592, rating: 4.5, dish: '孜然羊肉串', address: '夜宵烧烤 11 号', desc: '老板撒料毫不手软，孜然和辣椒面香得三条街外都闻得到。' },
  { id: 21, name: '蚝门夜档', emoji: '🦪', district: '夜宵烧烤', cat: '烧烤夜宵', x: 165, y: 618, rating: 4.6, dish: '蒜蓉烤生蚝', address: '夜宵烧烤 18 号', desc: '生蚝现开现烤，蒜蓉铺得满满当当，汁水在壳里咕嘟作响。' },

  { id: 22, name: '山城老灶', emoji: '🍲', district: '火锅江湖', cat: '火锅江湖', x: 470, y: 558, rating: 4.8, dish: '牛油九宫格', address: '火锅江湖 2 号', desc: '牛油锅底翻滚着红汤，毛肚七上八下十五秒，辣到冒汗也停不下来。' },
  { id: 23, name: '番茄暖锅', emoji: '🍅', district: '火锅江湖', cat: '火锅江湖', x: 600, y: 592, rating: 4.5, dish: '番茄牛腩锅', address: '火锅江湖 15 号', desc: '番茄熬到起沙，汤底酸甜浓稠，先喝汤再涮肉，不吃辣也能尽兴。' },
  { id: 24, name: '潮牛铺', emoji: '🥩', district: '火锅江湖', cat: '火锅江湖', x: 540, y: 618, rating: 4.7, dish: '手打牛肉丸', address: '火锅江湖 26 号', desc: '吊龙、匙柄按部位分开涮，每个部位都有最佳秒数，牛肉丸弹牙到能弹上桌。' }
]

const cats = ['全部', ...districts.map(d => d.key)]
const activeCat = ref('全部')
const selected = ref(null)

const visibleSpots = computed(() =>
  activeCat.value === '全部' ? spots : spots.filter(s => s.cat === activeCat.value)
)
function zoneActive(d) {
  return activeCat.value === '全部' || d.key === activeCat.value
}
function pinPos(s) {
  return { left: (s.x / 760 * 100) + '%', top: (s.y / 660 * 100) + '%' }
}
function starStr(n) {
  const f = Math.round(n)
  return '★'.repeat(f) + '☆'.repeat(5 - f)
}
function sameDistrict(s) {
  return spots.filter(o => o.district === s.district && o.id !== s.id)
}
function goRelated(s) {
  router.push({ path: '/', query: { cat: s.cat } })
}
function goProfile() {
  router.push('/profile')
}
function goRanking() {
  router.push('/ranking')
}

onMounted(() => {
  // 预选评分最高的店铺，让面板一进来就有内容
  selected.value = spots.reduce((a, b) => (b.rating > a.rating ? b : a), spots[0])
})
</script>

<template>
  <div class="mapview">
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>

    <div class="topbar">
      <button class="back" @click="router.push('/')">← 返回广场</button>
      <div class="top-right">
        <button class="mine" @click="goRanking">排行榜</button>
        <button class="mine" @click="goProfile">我的</button>
      </div>
    </div>

    <header class="mhead">
      <h1>🗺️ 食光城 · 美食地图</h1>
      <p>24 家宝藏店铺，按区逛吃，点图钉看好评与招牌</p>
    </header>

    <nav class="mfilter">
      <button v-for="c in cats" :key="c" :class="{ on: activeCat === c }" @click="activeCat = c">{{ c }}</button>
    </nav>

    <div class="map-layout">
      <div class="map-canvas">
        <svg class="map-svg" viewBox="0 0 760 660" preserveAspectRatio="xMidYMid meet" aria-hidden="true">
          <rect x="0" y="0" width="760" height="660" rx="28" fill="#f4f8ff" />
          <path d="M0,250 C160,210 300,300 460,250 S720,210 760,260 L760,300 C700,260 540,320 400,280 S140,250 0,300 Z" fill="#dceefc" opacity=".7" />
          <g v-for="d in districts" :key="d.key">
            <rect :x="d.x" :y="d.y" :width="d.w" :height="d.h" rx="22" :fill="d.fill" :opacity="zoneActive(d) ? 1 : .3" stroke="#ffffff" stroke-width="2" />
            <text :x="d.x + 18" :y="d.y + 30" font-size="15" font-weight="800" fill="#7a6a5d">{{ d.name }}</text>
            <text :x="d.x + 18" :y="d.y + 50" font-size="11" fill="#a99a8c">{{ d.key }}</text>
          </g>
          <line x1="385" y1="20" x2="385" y2="640" stroke="#ffffff" stroke-width="6" opacity=".55" />
          <line x1="30" y1="170" x2="730" y2="170" stroke="#ffffff" stroke-width="6" opacity=".55" />
          <line x1="30" y1="330" x2="730" y2="330" stroke="#ffffff" stroke-width="6" opacity=".55" />
          <line x1="30" y1="490" x2="730" y2="490" stroke="#ffffff" stroke-width="6" opacity=".55" />
        </svg>

        <button
          v-for="s in visibleSpots"
          :key="s.id"
          class="pin"
          :class="{ on: selected && selected.id === s.id }"
          :style="pinPos(s)"
          @click="selected = s"
        >
          <span class="pin-emoji">{{ s.emoji }}</span>
          <span class="pin-tip">{{ s.name }} · {{ s.rating }}★</span>
        </button>
      </div>

      <aside class="spot-panel">
        <template v-if="selected">
          <div class="sp-emoji">{{ selected.emoji }}</div>
          <h3>{{ selected.name }}</h3>
          <div class="sp-tags">
            <span class="sp-cat">{{ selected.cat }}</span>
            <span class="sp-dist">📍 {{ selected.district }}</span>
          </div>
          <div class="sp-rating">★ {{ selected.rating.toFixed(1) }}<small> 推荐指数</small></div>
          <div class="sp-row"><b>招牌</b>{{ selected.dish }}</div>
          <div class="sp-row"><b>地址</b>{{ selected.address }}</div>
          <p class="sp-desc">{{ selected.desc }}</p>
          <button class="sp-btn" @click="goRelated(selected)">查看相关美食 →</button>

          <div class="sp-same">
            <div class="sp-same-title">同区推荐</div>
            <div class="sp-same-list">
              <button v-for="o in sameDistrict(selected)" :key="o.id" class="sp-same-item" @click="selected = o">
                {{ o.emoji }} {{ o.name }}
              </button>
            </div>
          </div>
        </template>
        <div v-else class="sp-empty">👆 点击地图上的图钉，查看店铺详情与好评</div>
      </aside>
    </div>

    <p class="map-note">* 地图为前端示例数据，便于离线体验；后续可接入真实门店接口。</p>
  </div>
</template>

<style scoped>
.mapview{ position:relative; max-width:1040px; margin:0 auto; padding:24px 24px 60px; z-index:1; }
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

.mhead{ position:relative; z-index:2; margin-bottom:16px; }
.mhead h1{ font-size:26px; font-weight:800; }
.mhead p{ margin-top:6px; color:var(--muted); font-size:14px; }

.mfilter{ position:relative; z-index:2; display:flex; flex-wrap:wrap; gap:8px; margin-bottom:16px; }
.mfilter button{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:8px 16px; border-radius:20px; font-size:13.5px; font-weight:600; cursor:pointer; transition:.2s; }
.mfilter button:hover{ border-color:var(--orange); color:var(--orange); }
.mfilter button.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }

.map-layout{ position:relative; z-index:2; display:grid; grid-template-columns:1.7fr 1fr; gap:18px; align-items:start; }

.map-canvas{ position:relative; border-radius:22px; overflow:hidden; box-shadow:0 16px 40px rgba(255,90,60,.12);
  background:#f4f8ff; aspect-ratio:760/660; }
.map-svg{ position:absolute; inset:0; width:100%; height:100%; }

.pin{ position:absolute; transform:translate(-50%,-100%); display:flex; flex-direction:column; align-items:center;
  background:none; border:0; cursor:pointer; z-index:3; }
.pin-emoji{ font-size:22px; line-height:1; width:44px; height:44px; display:flex; align-items:center; justify-content:center;
  background:#fff; border:2.5px solid var(--tomato); border-radius:50%; position:relative;
  box-shadow:0 6px 14px rgba(255,90,60,.3); transition:.2s; }
.pin-emoji::after{ content:""; position:absolute; bottom:-7px; left:50%; transform:translateX(-50%) rotate(45deg);
  width:12px; height:12px; background:#fff; border-right:2.5px solid var(--tomato); border-bottom:2.5px solid var(--tomato); }
.pin:hover .pin-emoji{ transform:scale(1.12); }
.pin.on .pin-emoji{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:#fff; color:#fff; transform:scale(1.18); }
.pin.on .pin-emoji::after{ background:var(--tomato); }
.pin-tip{ margin-top:9px; font-size:11px; font-weight:700; color:#5b4a3c; background:rgba(255,255,255,.92);
  padding:2px 7px; border-radius:8px; white-space:nowrap; box-shadow:0 2px 6px rgba(0,0,0,.08); opacity:0; transition:.2s; pointer-events:none; }
.pin:hover .pin-tip, .pin.on .pin-tip{ opacity:1; }

.spot-panel{ position:relative; z-index:2; background:#fff; border-radius:22px; padding:22px;
  box-shadow:0 16px 40px rgba(255,90,60,.12); min-height:300px; animation:cardIn .4s backwards; }
@keyframes cardIn{ from{ opacity:0; transform:translateY(12px);} to{ opacity:1; transform:translateY(0);} }
.sp-emoji{ font-size:48px; }
.spot-panel h3{ font-size:21px; margin:6px 0 10px; }
.sp-tags{ display:flex; gap:8px; flex-wrap:wrap; margin-bottom:12px; }
.sp-cat{ font-size:12px; color:var(--tomato); background:#fff0ea; padding:3px 10px; border-radius:10px; font-weight:600; }
.sp-dist{ font-size:12px; color:var(--muted); background:#f4efe8; padding:3px 10px; border-radius:10px; }
.sp-rating{ font-size:22px; font-weight:800; color:var(--tomato); margin-bottom:14px; }
.sp-rating small{ font-size:12px; color:var(--muted); font-weight:600; }
.sp-row{ font-size:14px; color:#4a3d33; margin-bottom:8px; }
.sp-row b{ display:inline-block; width:42px; color:var(--muted); font-weight:700; }
.sp-desc{ font-size:13.5px; line-height:1.7; color:var(--muted); margin:10px 0 16px; }
.sp-btn{ width:100%; border:0; border-radius:12px; padding:11px; font-weight:700; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 8px 18px rgba(255,90,60,.3); transition:.2s; }
.sp-btn:hover{ filter:brightness(1.05); }
.sp-same{ margin-top:18px; border-top:1px dashed #ecdfd2; padding-top:14px; }
.sp-same-title{ font-size:12.5px; color:var(--muted); font-weight:700; margin-bottom:8px; }
.sp-same-list{ display:flex; flex-wrap:wrap; gap:8px; }
.sp-same-item{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted); padding:6px 11px;
  border-radius:11px; font-size:12.5px; cursor:pointer; transition:.2s; font-weight:600; }
.sp-same-item:hover{ border-color:var(--orange); color:var(--tomato); }
.sp-empty{ color:var(--muted); text-align:center; padding:60px 20px; font-size:14px; }

.map-note{ position:relative; z-index:2; margin-top:18px; font-size:12px; color:#b8a99a; text-align:center; }

@media (max-width:820px){
  .map-layout{ grid-template-columns:1fr; }
  .map-canvas{ aspect-ratio:760/720; }
}
</style>
