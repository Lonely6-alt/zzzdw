<script setup>
// 首页 / 列表通用美食卡片：
// - 多图轮播封面（ImgCarousel：懒加载 + 骨架屏 + 实拍水印）
// - 种草 🌱 / 避雷 ⚠️ 类型徽标
// - 热量、堂食/打包、忌口标签、营业状态
// - 悬浮浮窗：人均、营业时间，不用进详情页
import { computed } from 'vue'
import ImgCarousel from './ImgCarousel.vue'
import { useLikes } from '../composables/useLikes.js'
import { useFavorites } from '../composables/useFavorites.js'
import { useFoodMeta } from '../composables/useFoodMeta.js'

const props = defineProps({
  p: { type: Object, required: true }
})
const emit = defineEmits(['open'])

const { isLiked, countOf, toggle: toggleLike } = useLikes()
const { isFav, toggle: toggleFav } = useFavorites()
const { calorieOf, dietTagsOf, serveOf, avgPriceOf, hoursOf, openStatusOf, noteTypeOf } = useFoodMeta()

const shopPool = ['巷口小馆', '老地方食堂', '街角食光', '私房一味', '深夜食堂', '暖食屋', '半日闲', '食光小铺', '鲜物记', '好味来', '慢炖锅', '一味居']
const shopName = computed(() => props.p.shopName || shopPool[(Number(props.p.id) || 1) % shopPool.length])
const noteType = computed(() => noteTypeOf(props.p))
const cal = computed(() => calorieOf(props.p))
const dietTags = computed(() => dietTagsOf(props.p))
const serve = computed(() => serveOf(props.p))
const price = computed(() => avgPriceOf(props.p))
const hours = computed(() => hoursOf(props.p))
const openSt = computed(() => openStatusOf(props.p))

async function onLike() {
  if (isLiked(props.p.id)) return
  await toggleLike(props.p.id, props.p.likeCount || 0)
}
async function onFav() { await toggleFav(props.p.id) }
</script>

<template>
  <article class="card" @click="emit('open', p.id)">
    <!-- 封面：多图轮播 -->
    <div class="cover">
      <ImgCarousel :post="p" />
      <span class="type-badge" :class="noteType">
        {{ noteType === 'avoid' ? '⚠️ 避雷' : '🌱 种草' }}
      </span>
      <!-- 悬浮浮窗：人均 / 营业时间 / 状态 / 热量忌口速览 -->
      <div class="pop" @click.stop>
        <div class="pop-row">
          <span class="pop-status" :class="openSt.cls">
            <i class="dot"></i>{{ openSt.label }}
          </span>
          <span class="pop-price">人均 <b>¥{{ price }}</b></span>
        </div>
        <div class="pop-row muted">🕐 营业时间 {{ hours[0] }} – {{ hours[1] }}</div>
        <div class="pop-tags">
          <span class="pt" :class="cal.cls">🔥 {{ cal.text }}</span>
          <span class="pt">{{ serve }}</span>
          <span v-for="t in dietTags.slice(0, 2)" :key="t.text" class="pt" :class="t.cls">{{ t.text }}</span>
        </div>
      </div>
    </div>

    <div class="body">
      <h3 class="shop">{{ shopName }}</h3>
      <p class="line">{{ p.title }}</p>
      <div class="tags">
        <span class="tag" :class="cal.cls">🔥 {{ cal.text }}</span>
        <span class="tag serve">🍽️ {{ serve }}</span>
        <span v-for="t in dietTags.slice(0, 1)" :key="t.text" class="tag" :class="t.cls">{{ t.text }}</span>
      </div>
      <div class="meta">
        <span class="open" :class="openSt.cls"><i></i>{{ openSt.label }}</span>
        <button class="like" :class="{ on: isLiked(p.id) }" type="button" @click.stop="onLike">
          {{ isLiked(p.id) ? '❤️' : '🤍' }}<i>{{ countOf(p.id, p.likeCount || 0) }}</i>
        </button>
        <button class="fav" :class="{ on: isFav(p.id) }" type="button" @click.stop="onFav">
          {{ isFav(p.id) ? '★' : '☆' }}
        </button>
        <span class="cmt" @click.stop="emit('open', p.id)">💬 {{ p.reviewCount || 0 }}</span>
      </div>
    </div>
  </article>
</template>

<style scoped>
.card{ position:relative; background:#fff; border:1.5px solid #f6ebe0; border-radius:18px; overflow:visible; cursor:pointer;
  box-shadow:0 8px 20px rgba(255,120,80,.07); transition:transform .22s, box-shadow .22s, border-color .22s; }
.card:hover{ transform:translateY(-5px); box-shadow:0 18px 34px rgba(255,90,60,.16); border-color:#ffd9bf; }

/* ===== 封面 ===== */
.cover{ position:relative; width:100%; aspect-ratio:4 / 3; border-radius:18px 18px 0 0; overflow:visible;
  background:#f6eee6; }
.cover :deep(.carousel){ border-radius:18px 18px 0 0; }
/* 遮罩只盖住轮播可视区底部，让类型徽标更清晰 */
.cover::after{ content:""; position:absolute; left:0; right:0; bottom:0; height:34%; pointer-events:none; z-index:2;
  background:linear-gradient(to top,rgba(60,30,15,.30),rgba(60,30,15,0)); border-radius:0 0 18px 18px; }

.type-badge{ position:absolute; left:10px; top:10px; z-index:4; font-size:11px; font-weight:800;
  padding:3px 9px; border-radius:999px; backdrop-filter:blur(4px); }
.type-badge.plant{ color:#1d7a3e; background:rgba(226,250,233,.92); border:1px solid rgba(45,140,80,.25); }
.type-badge.avoid{ color:#c23b22; background:rgba(255,236,232,.94); border:1px solid rgba(200,70,50,.3); }

/* ===== 悬浮浮窗 ===== */
.pop{ position:absolute; left:8px; right:8px; bottom:10px; z-index:5;
  background:rgba(255,253,250,.96); backdrop-filter:blur(8px); border:1px solid #f3e2d0;
  border-radius:14px; padding:10px 12px; box-shadow:0 14px 30px rgba(120,50,20,.18);
  opacity:0; transform:translateY(8px); pointer-events:none; transition:.22s ease; }
.card:hover .pop{ opacity:1; transform:translateY(0); pointer-events:auto; }
.pop-row{ display:flex; align-items:center; justify-content:space-between; gap:8px; font-size:12px; color:#5c4a3a; }
.pop-row.muted{ margin-top:5px; color:#9b8c7e; font-size:11.5px; }
.pop-price b{ color:var(--tomato); font-size:14px; }
.pop-status{ display:flex; align-items:center; gap:5px; font-weight:800; font-size:11.5px; }
.pop-status .dot{ width:7px; height:7px; border-radius:50%; display:inline-block; }
.pop-status.on{ color:#1d7a3e; } .pop-status.on .dot{ background:#2f9a5d; }
.pop-status.warn{ color:#b07010; } .pop-status.warn .dot{ background:#f5a623; }
.pop-status.off{ color:#9b8c7e; } .pop-status.off .dot{ background:#c4ab94; }
.pop-tags{ display:flex; flex-wrap:wrap; gap:5px; margin-top:7px; }
.pt{ font-size:10.5px; font-weight:700; padding:2px 7px; border-radius:8px; background:#f6eee6; color:#7a6a5d; }
.pt.low,.pt.safe{ background:#e9f7ee; color:#1d7a3e; }
.pt.mid{ background:#fff1e0; color:#b07010; }
.pt.high,.pt.warn{ background:#fdeae6; color:#c23b22; }

/* ===== 卡片主体 ===== */
.body{ padding:11px 13px 12px; background:#fff; }
.shop{ font-size:13.5px; font-weight:800; color:var(--ink); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; margin:0; }
.line{ font-size:12.5px; color:#9b8c7e; line-height:1.5; margin:4px 0 0; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.tags{ display:flex; flex-wrap:wrap; gap:5px; margin-top:7px; }
.tag{ font-size:10.5px; font-weight:700; padding:2px 7px; border-radius:8px; background:#f6eee6; color:#7a6a5d; }
.tag.low,.tag.safe{ background:#e9f7ee; color:#1d7a3e; }
.tag.mid,.tag.serve{ background:#fff1e0; color:#b07010; }
.tag.high,.tag.warn{ background:#fdeae6; color:#c23b22; }
.meta{ display:flex; align-items:center; gap:10px; margin-top:9px; padding-top:8px; border-top:1px dashed #f2e7db; }
.open{ display:flex; align-items:center; gap:5px; font-size:11.5px; font-weight:800; }
.open i{ width:7px; height:7px; border-radius:50%; display:inline-block; }
.open.on{ color:#1d7a3e; } .open.on i{ background:#2f9a5d; animation:pulse 1.6s infinite; }
.open.warn{ color:#b07010; } .open.warn i{ background:#f5a623; }
.open.off{ color:#9b8c7e; } .open.off i{ background:#c4ab94; }
@keyframes pulse{ 0%,100%{ opacity:1; } 50%{ opacity:.4; } }
.like,.fav{ display:flex; align-items:center; gap:4px; border:0; background:transparent; cursor:pointer;
  font-size:12px; color:var(--muted); padding:0; font-family:inherit; transition:.15s; }
.like:hover,.fav:hover{ color:var(--tomato); }
.like i{ font-style:normal; font-weight:700; }
.like.on,.fav.on{ color:var(--tomato); }
.fav{ font-size:14px; }
.cmt{ margin-left:auto; font-size:12px; color:var(--muted); }
.cmt:hover{ color:var(--tomato); }
</style>
