<template>
  <div class="hsw">
    <button
      v-show="canPrev"
      type="button"
      class="hsw-btn prev"
      aria-label="上一页"
      @click="go(-1)"
    >‹</button>
    <div ref="track" class="hsw-track" @scroll.passive="update">
      <slot />
    </div>
    <button
      v-show="canNext"
      type="button"
      class="hsw-btn next"
      aria-label="下一页"
      @click="go(1)"
    >›</button>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'

const track = ref(null)
const canPrev = ref(false)
const canNext = ref(false)
let ro = null

function update() {
  const el = track.value
  if (!el) return
  canPrev.value = el.scrollLeft > 4
  canNext.value = el.scrollLeft < el.scrollWidth - el.clientWidth - 4
}

// 翻一页：按容器可视宽度滚动，留一点重叠避免漏看
function go(dir) {
  const el = track.value
  if (!el) return
  el.scrollBy({ left: dir * el.clientWidth * 0.9, behavior: 'smooth' })
}

onMounted(async () => {
  await nextTick()
  update()
  // 内容宽度变化（图片加载、数据更新）时刷新按钮显隐
  ro = new ResizeObserver(update)
  if (track.value) ro.observe(track.value)
})
onUnmounted(() => { if (ro) ro.disconnect() })
</script>

<style scoped>
.hsw{ position:relative; }
.hsw-track{ display:flex; gap:12px; overflow-x:auto; padding:2px 2px 10px; scrollbar-width:none; }
.hsw-track::-webkit-scrollbar{ display:none; }

/* 左右翻页按钮：悬浮在板块两侧 */
.hsw-btn{
  position:absolute; top:50%; transform:translateY(-50%); z-index:5;
  width:34px; height:34px; border-radius:50%; border:0; cursor:pointer;
  font-size:20px; line-height:1; font-weight:700; color:#9b6a4a;
  background:rgba(255,255,255,.95); box-shadow:0 6px 16px rgba(180,90,50,.25);
  display:flex; align-items:center; justify-content:center;
  transition:transform .18s, background .18s, color .18s;
  font-family:inherit; padding-bottom:3px;
}
.hsw-btn:hover{ background:linear-gradient(120deg,#ff8a4c,#ff5f3d); color:#fff; transform:translateY(-50%) scale(1.1); }
.hsw-btn.prev{ left:-6px; }
.hsw-btn.next{ right:-6px; }
</style>
