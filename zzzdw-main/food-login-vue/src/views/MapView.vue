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

  { id: 25, name: '山城小面', emoji: '🌶️', district: '老城面巷', cat: '面食控', x: 105, y: 60, rating: 4.5, dish: '豌杂小面', address: '老城面巷 33 号', desc: '豌豆耙软、杂酱焦香，红油辣子是现舂的，拌开就是老重庆的早晨。' },
  { id: 26, name: '渔火船屋', emoji: '🚤', district: '海湾日料', cat: '日料局', x: 685, y: 65, rating: 4.6, dish: '帆立贝炙烧', address: '海湾码头 1 号', desc: '开在船屋里的居酒屋，帆立贝现点现炙，配上港风海风，氛围感拉满。' },
  { id: 27, name: '碳水俱乐部', emoji: '🥖', district: '炸鸡广场', cat: '汉堡炸鸡', x: 330, y: 215, rating: 4.4, dish: '黄油可颂堡', address: '炸鸡广场 21 号', desc: '可颂做汉堡胚，咬下去黄油簌簌掉渣，肉汁浸进酥皮里太犯规。' },
  { id: 28, name: '森之便当', emoji: '🍱', district: '轻食绿洲', cat: '轻食沙拉', x: 415, y: 255, rating: 4.5, dish: '彩虹能量便当', address: '轻食绿洲 30 号', desc: '一天只做 60 份的手作便当，五色配菜不重样，打工人的快乐盒子。' },
  { id: 29, name: '布丁车站', emoji: '🍮', district: '甜心巷', cat: '甜品时间', x: 355, y: 370, rating: 4.6, dish: '烤布蕾火车便当', address: '甜心巷 1 号', desc: '把甜品装进小火车造型的盒子，焦糖脆壳敲下去咔嚓一声，幸福感具象化。' },
  { id: 30, name: '豆波跑道', emoji: '🧋', district: '咖啡街角', cat: '咖啡馆', x: 715, y: 400, rating: 4.5, dish: '桂花酒酿奶茶', address: '咖啡街角 28 号', desc: '酒酿桂花打底，茶底现萃，喝到最后能嚼到圆滚滚的小丸子。' },
  { id: 31, name: '深夜食堂', emoji: '🍜', district: '夜宵烧烤', cat: '烧烤夜宵', x: 105, y: 545, rating: 4.8, dish: '猫饭茶泡饭', address: '夜宵烧烤 25 号', desc: '凌晨一点还亮灯的小店，老板只有一道菜谱：随心情变化的茶泡饭。' },
  { id: 32, name: '牛潮码头', emoji: '🐂', district: '火锅江湖', cat: '火锅江湖', x: 715, y: 550, rating: 4.6, dish: '吊龙伴牛杂锅', address: '火锅江湖 31 号', desc: '每天只进两头的潮汕黄牛，牛杂锅免费续汤，吃到扶墙才肯走。' },

  { id: 22, name: '山城老灶', emoji: '🍲', district: '火锅江湖', cat: '火锅江湖', x: 470, y: 558, rating: 4.8, dish: '牛油九宫格', address: '火锅江湖 2 号', desc: '牛油锅底翻滚着红汤，毛肚七上八下十五秒，辣到冒汗也停不下来。' },
  { id: 23, name: '番茄暖锅', emoji: '🍅', district: '火锅江湖', cat: '火锅江湖', x: 600, y: 592, rating: 4.5, dish: '番茄牛腩锅', address: '火锅江湖 15 号', desc: '番茄熬到起沙，汤底酸甜浓稠，先喝汤再涮肉，不吃辣也能尽兴。' },
  { id: 24, name: '潮牛铺', emoji: '🥩', district: '火锅江湖', cat: '火锅江湖', x: 540, y: 618, rating: 4.7, dish: '手打牛肉丸', address: '火锅江湖 26 号', desc: '吊龙、匙柄按部位分开涮，每个部位都有最佳秒数，牛肉丸弹牙到能弹上桌。' }
]

const selected = ref(null)
// 「查看相关美食」不再跳首页：直接在面板里展开相关内容
const showRelated = ref(false)

// 相关美食 = 同美食分类的其他点位（跨区聚合），按评分倒序
const relatedSpots = computed(() => {
  if (!selected.value) return []
  return spots
    .filter(s => s.cat === selected.value.cat && s.id !== selected.value.id)
    .sort((a, b) => b.rating - a.rating)
})

// 换点位时收起相关内容，避免上一家的数据残留
function pickSpot(s) {
  if (selected.value && selected.value.id === s.id) return
  selected.value = s
  showRelated.value = false
}

// ---- 真实店铺层：直接读 /api/shops，与数据库里的门店一一对应 ----
const view = ref('map')          // map=插画地图 / shops=真实店铺
const shops = ref([])
const shopsLoading = ref(false)
const shopsErr = ref('')
const shopLoaded = ref(false)
const activeDistrict = ref('')

const shopDistricts = computed(() =>
  [...new Set(shops.value.map(s => s.district).filter(Boolean))]
)

const visibleShops = computed(() => {
  const list = activeDistrict.value
    ? shops.value.filter(s => s.district === activeDistrict.value)
    : shops.value
  // 有菜、评分高的排前面，避免空店铺占满首屏
  return [...list].sort((a, b) =>
    (b.postCount || 0) - (a.postCount || 0) || (b.avgRating || 0) - (a.avgRating || 0)
  )
})

async function loadShops() {
  if (shopLoaded.value || shopsLoading.value) return
  shopsLoading.value = true
  try {
    const r = await fetch('/api/shops')
    if (!r.ok) throw new Error('店铺加载失败')
    shops.value = await r.json()
    shopLoaded.value = true
  } catch (e) {
    shopsErr.value = e.message
  } finally {
    shopsLoading.value = false
  }
}
function switchView(v) {
  view.value = v
  if (v === 'shops') loadShops()
}
function openShop(s) { router.push(`/shop/${s.shopId}`) }

const visibleSpots = computed(() => spots)
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
// 面板内查看相关美食内容，不跳转首页
function toggleRelated() {
  showRelated.value = !showRelated.value
}
// 返回上一个页面；直接进入本页没有历史时才回首页
function goBack() {
  if (window.history.state && window.history.state.back != null) router.back()
  else router.push('/')
}
function goProfile() {
  router.push('/profile')
}
function goRanking() {
  router.push('/ranking')
}
// 地址跳转导航：高德 URI 在手机上唤起 App、桌面端打开网页，keyword 为店铺名+地址
function navigate(name, address) {
  const kw = [name, address].filter(Boolean).join(' ')
  if (!kw) return
  const url = `https://uri.amap.com/search?keyword=${encodeURIComponent(kw)}&callnative=1&src=food-community`
  window.open(url, '_blank')
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
      <button class="back" @click="goBack">← 返回广场</button>
      <div class="top-right">
        <button class="mine" @click="goRanking">排行榜</button>
        <button class="mine" @click="goProfile">我的</button>
      </div>
    </div>

    <header class="mhead">
      <h1>🗺️ 食光城 · 美食地图</h1>
      <p v-if="view === 'map'">{{ spots.length }} 家宝藏店铺，按区逛吃，点图钉看好评与招牌</p>
      <p v-else>{{ shops.length }} 家真实门店，按商圈逛逛，点进去看菜单</p>
    </header>

    <nav class="viewtabs">
      <button :class="{ on: view === 'map' }" @click="switchView('map')">🗺️ 插画地图</button>
      <button :class="{ on: view === 'shops' }" @click="switchView('shops')">🏠 真实店铺</button>
    </nav>

    <div v-if="view === 'map'" class="map-layout">
      <div class="map-canvas">
        <svg class="map-svg" viewBox="0 0 760 660" preserveAspectRatio="xMidYMid meet" aria-hidden="true">
          <rect x="0" y="0" width="760" height="660" rx="28" fill="#f4f8ff" />
          <path d="M0,250 C160,210 300,300 460,250 S720,210 760,260 L760,300 C700,260 540,320 400,280 S140,250 0,300 Z" fill="#dceefc" opacity=".7" />
          <!-- 新增装饰：小河上的船、街心公园、口袋公园、行道树、灯塔 -->
          <path d="M0,250 C160,210 300,300 460,250 S720,210 760,260" fill="none" stroke="#b9dcf3" stroke-width="3" opacity=".8" />
          <text x="596" y="248" font-size="22">⛵</text>
          <text x="268" y="258" font-size="15" opacity=".8">🦆</text>
          <g opacity=".9">
            <circle cx="384" cy="222" r="17" fill="#cdeccf" />
            <circle cx="374" cy="216" r="5" fill="#9fd8a4" />
            <circle cx="392" cy="214" r="6" fill="#8ecf94" />
            <circle cx="384" cy="228" r="4.5" fill="#9fd8a4" />
            <text x="376" y="247" font-size="9" fill="#7ba981">街心公园</text>
          </g>
          <g opacity=".85">
            <circle cx="358" cy="530" r="14" fill="#d4f0d6" />
            <circle cx="350" cy="526" r="4.5" fill="#9fd8a4" />
            <circle cx="364" cy="524" r="5" fill="#8ecf94" />
            <text x="348" y="550" font-size="9" fill="#7ba981">口袋公园</text>
          </g>
          <g opacity=".8">
            <rect x="736" y="196" width="5" height="18" rx="2" fill="#f3c9b8" />
            <circle cx="738" cy="194" r="7" fill="#ffd0ba" />
          </g>
          <text x="24" y="146" font-size="13">🌳</text>
          <text x="336" y="150" font-size="12">🌲</text>
          <text x="726" y="640" font-size="13">🌲</text>
          <text x="40" y="640" font-size="12">🌳</text>
          <text x="452" y="145" font-size="11">🗼</text>
          <g v-for="d in districts" :key="d.key">
            <rect :x="d.x" :y="d.y" :width="d.w" :height="d.h" rx="22" :fill="d.fill" opacity="1" stroke="#ffffff" stroke-width="2" />
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
          @click="pickSpot(s)"
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
          <div class="sp-row sp-address">
            <b>地址</b>
            <span>{{ selected.address }}</span>
            <button class="sp-nav" type="button" title="打开导航" @click="navigate(selected.name, selected.address)">🧭 导航</button>
          </div>
          <p class="sp-desc">{{ selected.desc }}</p>
          <button class="sp-btn" @click="toggleRelated">
            {{ showRelated ? '收起相关美食 ↑' : `查看相关美食（${relatedSpots.length} 家同分类） ↓` }}
          </button>

          <!-- 相关美食内容：直接在面板内展开，不再跳转首页 -->
          <div v-if="showRelated" class="sp-related">
            <div class="sp-rel-head">
              <span class="sp-rel-tag">{{ selected.cat }}</span>
              <span class="sp-rel-sub">食光城里还有 {{ relatedSpots.length }} 家同分类好店</span>
            </div>
            <button
              v-for="r in relatedSpots"
              :key="'r' + r.id"
              class="sp-rel-item"
              :class="{ top: r.rating >= 4.8 }"
              @click="pickSpot(r)"
            >
              <span class="sp-rel-emoji">{{ r.emoji }}</span>
              <span class="sp-rel-info">
                <b>{{ r.name }}</b>
                <small>📍 {{ r.district }} · 招牌 {{ r.dish }}</small>
              </span>
              <span class="sp-rel-rating">★ {{ r.rating.toFixed(1) }}</span>
            </button>
            <p v-if="!relatedSpots.length" class="sp-rel-empty">这个分类目前只有这一家，去别的区逛逛吧～</p>
          </div>

          <div class="sp-same">
            <div class="sp-same-title">同区推荐</div>
            <div class="sp-same-list">
              <button v-for="o in sameDistrict(selected)" :key="o.id" class="sp-same-item" @click="pickSpot(o)">
                {{ o.emoji }} {{ o.name }}
              </button>
            </div>
          </div>
        </template>
        <div v-else class="sp-empty">👆 点击地图上的图钉，查看店铺详情与好评</div>
      </aside>
    </div>

    <!-- 真实店铺层：按商圈筛选的真实门店卡片 -->
    <section v-else class="shops">
      <p v-if="shopsLoading" class="sp-empty">店铺加载中…</p>
      <p v-else-if="shopsErr" class="sp-empty">{{ shopsErr }}</p>
      <template v-else>
        <div class="district-chips">
          <button :class="{ on: activeDistrict === '' }" @click="activeDistrict = ''">
            全部商圈 <em>{{ shops.length }}</em>
          </button>
          <button v-for="d in shopDistricts" :key="d"
                  :class="{ on: activeDistrict === d }" @click="activeDistrict = d">
            {{ d }}
            <em>{{ shops.filter(s => s.district === d).length }}</em>
          </button>
        </div>

        <div v-if="visibleShops.length" class="shop-grid">
          <article v-for="s in visibleShops" :key="s.shopId" class="shop-card" @click="openShop(s)">
            <div class="sc-top">
              <span class="sc-emoji">{{ s.emoji || '🏠' }}</span>
              <span class="sc-state" :class="s.status">{{ s.status === 'active' ? '营业中' : '休息中' }}</span>
            </div>
            <h3>{{ s.shopName }}</h3>
            <p class="sc-desc">{{ s.description || '这家店还没写简介～' }}</p>
            <div class="sc-meta">
              <button
                v-if="s.district"
                type="button"
                class="sc-nav"
                title="打开导航"
                @click.stop="navigate(s.shopName, s.district)"
              >📍 {{ s.district }} <em>导航 ›</em></button>
              <span v-else-if="s.district">📍 {{ s.district }}</span>
              <span v-if="s.ownerName">👤 @{{ s.ownerName }}</span>
            </div>
            <div class="sc-foot">
              <span class="sc-num">{{ s.postCount ?? 0 }}<small> 道菜</small></span>
              <span class="sc-stars">★ {{ Number(s.avgRating || 0).toFixed(1) }}</span>
              <span class="sc-num">{{ s.reviewCount ?? 0 }}<small> 点评</small></span>
            </div>
          </article>
        </div>
        <p v-else class="sp-empty">这个商圈还没有店铺</p>
      </template>
    </section>

    <p class="map-note" v-if="view === 'map'">* 插画地图为前端示例数据，便于离线体验。</p>
    <p class="map-note" v-else>* 这里展示的是数据库中的真实门店，点卡片可进店看菜单。</p>
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
.sp-address{ display:flex; align-items:center; flex-wrap:wrap; gap:6px; }
.sp-nav{ margin-left:auto; border:none; border-radius:999px; padding:4px 10px; font-size:12px; font-weight:700;
  color:#fff; cursor:pointer; font-family:inherit; background:linear-gradient(120deg,#ff9a52,#ff5f3d); transition:.2s; }
.sp-nav:hover{ transform:translateY(-1px); box-shadow:0 4px 10px rgba(255,95,61,.3); }
.sp-desc{ font-size:13.5px; line-height:1.7; color:var(--muted); margin:10px 0 16px; }
.sp-btn{ width:100%; border:0; border-radius:12px; padding:11px; font-weight:700; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 8px 18px rgba(255,90,60,.3); transition:.2s; }
.sp-btn:hover{ filter:brightness(1.05); }
.sp-related{ margin-top:14px; border:1.5px solid #fff0ea; background:#fffaf6; border-radius:16px; padding:14px; }
.sp-rel-head{ display:flex; align-items:center; gap:8px; margin-bottom:10px; flex-wrap:wrap; }
.sp-rel-tag{ font-size:12px; font-weight:800; color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato)); padding:3px 10px; border-radius:10px; }
.sp-rel-sub{ font-size:12px; color:var(--muted); }
.sp-rel-item{ display:flex; align-items:center; gap:10px; width:100%; text-align:left;
  background:#fff; border:1.5px solid #f6ebe0; border-radius:13px; padding:9px 11px; margin-bottom:8px;
  cursor:pointer; transition:.2s; font-family:inherit; }
.sp-rel-item:last-of-type{ margin-bottom:0; }
.sp-rel-item:hover{ border-color:var(--orange); transform:translateX(3px); box-shadow:0 8px 16px rgba(255,90,60,.12); }
.sp-rel-item.top{ border-color:#ffd9bf; background:#fff7ef; }
.sp-rel-emoji{ font-size:22px; flex-shrink:0; }
.sp-rel-info{ flex:1; min-width:0; display:flex; flex-direction:column; gap:3px; }
.sp-rel-info b{ font-size:13.5px; }
.sp-rel-info small{ font-size:11.5px; color:var(--muted); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.sp-rel-rating{ font-size:12.5px; font-weight:800; color:var(--tomato); flex-shrink:0; }
.sp-rel-item.top .sp-rel-rating::after{ content:" 顶"; font-size:10px; color:#e8a23c; font-weight:700; }
.sp-rel-empty{ font-size:12.5px; color:var(--muted); text-align:center; padding:10px 0 2px; }
.sp-same{ margin-top:18px; border-top:1px dashed #ecdfd2; padding-top:14px; }
.sp-same-title{ font-size:12.5px; color:var(--muted); font-weight:700; margin-bottom:8px; }
.sp-same-list{ display:flex; flex-wrap:wrap; gap:8px; }
.sp-same-item{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted); padding:6px 11px;
  border-radius:11px; font-size:12.5px; cursor:pointer; transition:.2s; font-weight:600; }
.sp-same-item:hover{ border-color:var(--orange); color:var(--tomato); }
.sp-empty{ color:var(--muted); text-align:center; padding:60px 20px; font-size:14px; }

/* 图层切换 */
.viewtabs{ position:relative; z-index:2; display:flex; gap:8px; margin-bottom:14px; }
.viewtabs button{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:9px 18px; border-radius:20px; font-size:13.5px; font-weight:700; cursor:pointer; transition:.2s; }
.viewtabs button:hover{ border-color:var(--orange); color:var(--orange); }
.viewtabs button.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff;
  box-shadow:0 8px 18px rgba(255,90,60,.26); }

/* 真实店铺层 */
.shops{ position:relative; z-index:2; }
.district-chips{ display:flex; flex-wrap:wrap; gap:8px; margin-bottom:16px; }
.district-chips button{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:7px 14px; border-radius:18px; font-size:13px; font-weight:600; cursor:pointer; transition:.2s; }
.district-chips button em{ font-style:normal; font-size:11.5px; opacity:.65; margin-left:4px; }
.district-chips button:hover{ border-color:var(--orange); color:var(--tomato); }
.district-chips button.on{ background:linear-gradient(120deg,var(--orange),var(--tomato)); border-color:transparent; color:#fff; }
.district-chips button.on em{ opacity:.85; }

.shop-grid{ display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.shop-card{ background:#fff; border-radius:18px; padding:18px; cursor:pointer;
  box-shadow:0 8px 22px rgba(0,0,0,.05); border:1px solid #f6ede2;
  transition:transform .2s, box-shadow .2s; animation:cardIn .45s backwards; display:flex; flex-direction:column; }
.shop-card:hover{ transform:translateY(-4px); box-shadow:0 16px 32px rgba(255,90,60,.18); }
.sc-top{ display:flex; align-items:flex-start; justify-content:space-between; }
.sc-emoji{ font-size:32px; line-height:1; }
.sc-state{ font-size:11px; font-weight:800; padding:3px 9px; border-radius:999px; }
.sc-state.active{ background:#e9f7ee; color:var(--ok); }
.sc-state.closed{ background:#f1ece5; color:var(--muted); }
.shop-card h3{ font-size:16px; margin:10px 0 6px; }
.sc-desc{ font-size:12.5px; color:var(--muted); line-height:1.5; min-height:38px;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.sc-meta{ display:flex; flex-wrap:wrap; gap:10px; margin-top:10px; font-size:12px; color:var(--muted); }
.sc-nav{ border:none; background:#fff1e6; color:#d1552f; border-radius:999px; padding:3px 9px; font-size:12px;
  cursor:pointer; font-family:inherit; transition:.2s; }
.sc-nav:hover{ background:#ffe0cc; }
.sc-nav em{ font-style:normal; font-weight:800; margin-left:3px; }
.sc-foot{ display:flex; align-items:center; gap:14px; margin-top:12px; padding-top:10px;
  border-top:1px dashed #f0e6db; font-size:12.5px; color:var(--muted); }
.sc-num{ font-weight:700; color:var(--ink); }
.sc-num small{ font-weight:500; color:var(--muted); font-size:11px; }
.sc-stars{ color:#f5a623; font-weight:700; }

.map-note{ position:relative; z-index:2; margin-top:18px; font-size:12px; color:#b8a99a; text-align:center; }

@media (max-width:820px){
  .map-layout{ grid-template-columns:1fr; }
  .map-canvas{ aspect-ratio:760/720; }
  .shop-grid{ grid-template-columns:repeat(2,1fr); }
}
@media (max-width:520px){
  .shop-grid{ grid-template-columns:1fr; }
}
</style>
