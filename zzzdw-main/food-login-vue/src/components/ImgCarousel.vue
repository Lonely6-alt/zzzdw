<script setup>
// 卡片多图横向轮播：小圆点指示器 + 图片懒加载 + 加载中的美食骨架屏 +
// 实拍图自动叠加平台浅水印。滑动支持鼠标/触摸，也支持小圆点直达。
import { ref, computed } from 'vue'
import { useFoodMeta } from '../composables/useFoodMeta.js'

const props = defineProps({
  post: { type: Object, required: true }
})

const { galleryOf } = useFoodMeta()
const slides = computed(() => galleryOf(props.post))

const idx = ref(0)
const total = computed(() => slides.value.length)
// 每张图的加载状态：imgLoaded[key] = true 后隐藏骨架屏
const imgLoaded = ref({})

function loaded(key) { return !!imgLoaded.value[key] }
function onImgLoad(key) { imgLoaded.value = { ...imgLoaded.value, [key]: true } }
function onImgError(key) { imgLoaded.value = { ...imgLoaded.value, [key]: 'err' } }

function goTo(i) { idx.value = (i + total.value) % total.value }
function prev() { goTo(idx.value - 1) }
function next() { goTo(idx.value + 1) }

// 触摸滑动切图
let startX = 0
function onTouchStart(e) { startX = e.touches[0].clientX }
function onTouchEnd(e) {
  const dx = e.changedTouches[0].clientX - startX
  if (Math.abs(dx) > 36) (dx < 0 ? next() : prev())
}
</script>

<template>
  <div class="carousel" @touchstart.passive="onTouchStart" @touchend.passive="onTouchEnd">
    <div class="track" :style="{ transform: `translateX(-${idx * 100}%)` }">
      <div v-for="(s, i) in slides" :key="i" class="slide" :style="{ background: s.bg || '#f6eee6' }">
        <!-- 图片页：懒加载 + 加载骨架屏 -->
        <template v-if="s.kind === 'photo' || s.kind === 'illus'">
          <img
            v-if="loaded(i) !== 'err'"
            :src="s.url"
            :alt="post.title"
            loading="lazy"
            decoding="async"
            @load="onImgLoad(i)"
            @error="onImgError(i)"
          />
          <div v-else class="em-slide"><span class="em">{{ post.emoji || '🍽️' }}</span></div>
          <!-- 美食骨架屏：图片未就绪时占位 -->
          <transition name="fade">
            <div v-if="loaded(i) !== true && loaded(i) !== 'err'" class="food-skeleton">
              <span class="sk-bowl">🍜</span>
              <span class="sk-steam"></span>
            </div>
          </transition>
        </template>
        <!-- emoji 渐变卡页 -->
        <div v-else class="em-slide">
          <span class="em">{{ s.emoji }}</span>
        </div>

        <!-- 平台浅水印：仅实拍图叠加 -->
        <div v-if="s.watermark" class="wm" aria-hidden="true">
          <span>光食 · 美食社区</span>
          <span>光食 · 美食社区</span>
        </div>
      </div>
    </div>

    <!-- 左右切换（桌面 hover 显示） -->
    <button v-if="total > 1" class="nav n-prev" type="button" aria-label="上一张" @click.stop="prev">‹</button>
    <button v-if="total > 1" class="nav n-next" type="button" aria-label="下一张" @click.stop="next">›</button>

    <!-- 小圆点指示器 -->
    <div v-if="total > 1" class="dots">
      <button
        v-for="(s, i) in slides"
        :key="'d' + i"
        type="button"
        class="dot"
        :class="{ on: idx === i }"
        :aria-label="`第 ${i + 1} 张图`"
        @click.stop="goTo(i)"
      />
    </div>
  </div>
</template>

<style scoped>
.carousel{ position:absolute; inset:0; overflow:hidden; }
.track{ display:flex; height:100%; transition:transform .4s cubic-bezier(.4,0,.2,1); }
.slide{ position:relative; flex:0 0 100%; height:100%; overflow:hidden; display:flex; align-items:center; justify-content:center; }
.slide img{ width:100%; height:100%; object-fit:cover; display:block; }

/* emoji 兜底页 */
.em-slide{ display:flex; align-items:center; justify-content:center; width:100%; height:100%; }
.em{ font-size:56px; line-height:1; padding:16px; border-radius:50%;
  background:rgba(255,255,255,.55); box-shadow:0 10px 26px rgba(160,90,50,.18), inset 0 0 0 1.5px rgba(255,255,255,.7); }

/* 美食骨架屏：热气腾腾的一碗面 */
.food-skeleton{ position:absolute; inset:0; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:6px;
  background:linear-gradient(100deg,#f6eee6 30%,#fbf5ee 45%,#f6eee6 60%); background-size:220% 100%;
  animation:skShimmer 1.3s ease-in-out infinite; }
@keyframes skShimmer{ 0%{ background-position:120% 0; } 100%{ background-position:-120% 0; } }
.sk-bowl{ font-size:34px; animation:steam 1.6s ease-in-out infinite; }
@keyframes steam{ 0%,100%{ transform:translateY(0) rotate(-3deg); opacity:.85; } 50%{ transform:translateY(-5px) rotate(3deg); opacity:1; } }
.sk-steam{ width:46px; height:3px; border-radius:2px; background:#e9dbcc; }
.fade-enter-active,.fade-leave-active{ transition:opacity .25s; }
.fade-enter-from,.fade-leave-to{ opacity:0; }

/* 平台浅水印：右下角斜排两行，半透明白 */
.wm{ position:absolute; inset:0; pointer-events:none; overflow:hidden; }
.wm span{ position:absolute; font-size:11px; font-weight:700; letter-spacing:2px;
  color:rgba(255,255,255,.5); text-shadow:0 1px 2px rgba(0,0,0,.12);
  transform:rotate(-18deg); white-space:nowrap; }
.wm span:nth-child(1){ right:-14px; bottom:34px; }
.wm span:nth-child(2){ right:36px; bottom:12px; font-size:9px; opacity:.75; }

/* 左右切换按钮 */
.nav{ position:absolute; top:50%; transform:translateY(-50%); z-index:3; width:26px; height:26px;
  border:0; border-radius:50%; cursor:pointer; font-size:15px; line-height:1; color:#7a5c40;
  background:rgba(255,255,255,.85); box-shadow:0 3px 10px rgba(120,60,20,.18);
  opacity:0; transition:.2s; }
.carousel:hover .nav{ opacity:1; }
.n-prev{ left:6px; } .n-next{ right:6px; }

/* 圆点指示器 */
.dots{ position:absolute; left:0; right:0; bottom:8px; z-index:3; display:flex; justify-content:center; gap:5px; }
.dot{ width:6px; height:6px; padding:0; border:0; border-radius:50%; cursor:pointer;
  background:rgba(255,255,255,.5); box-shadow:0 1px 3px rgba(0,0,0,.18); transition:.25s; }
.dot.on{ width:14px; border-radius:3px; background:#fff; }
</style>
