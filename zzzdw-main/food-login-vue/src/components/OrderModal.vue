<script setup>
import { ref } from 'vue'
import { useOrder } from '../composables/useOrder.js'

const { current, visible, done, closeOrder, placeOrder } = useOrder()
const qty = ref(1)
const note = ref('')

function confirm() {
  placeOrder({ qty: qty.value, note: note.value.trim() })
}
function onClose() {
  qty.value = 1
  note.value = ''
  closeOrder()
}
</script>

<template>
  <div v-if="visible" class="omask" @click.self="onClose">
    <div class="osheet">
      <button class="oclose" @click="onClose" aria-label="关闭">✕</button>

      <template v-if="!done">
        <div class="ohead">
          <div class="oemoji">{{ current?.emoji }}</div>
          <div class="oinfo">
            <div class="otitle">{{ current?.title }}</div>
            <div class="ometa">{{ current?.category }}<span v-if="current?.author"> · @{{ current.author }}</span></div>
          </div>
        </div>

        <div class="orow">
          <span class="olabel">数量</span>
          <div class="stepper">
            <button type="button" @click="qty > 1 && (qty--)">−</button>
            <span>{{ qty }}</span>
            <button type="button" @click="qty++">＋</button>
          </div>
        </div>

        <div class="orow col">
          <span class="olabel">备注</span>
          <input v-model="note" maxlength="40" placeholder="例如：少辣、不要香菜…" />
        </div>

        <button class="obtn" type="button" @click="confirm">确认下单（{{ qty }} 份）</button>
        <p class="otip">前端演示下单 · 后端下单接口待接入 🚧</p>
      </template>

      <div v-else class="odone">
        <div class="odone-emoji">🍱</div>
        <h3>下单成功！</h3>
        <p>已为你记下「{{ current?.title }}」× {{ qty }}</p>
        <p class="odone-sub">（前端演示数据，已存入本地订单）</p>
        <button class="obtn" type="button" @click="onClose">好的</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.omask{ position:fixed; inset:0; background:rgba(40,20,10,.45); display:flex; align-items:center; justify-content:center;
  padding:20px; z-index:50; animation:ofade .2s ease; }
@keyframes ofade{ from{ opacity:0; } to{ opacity:1; } }
.osheet{ position:relative; background:#fff; border-radius:20px; padding:24px; width:min(420px,100%);
  box-shadow:0 24px 60px rgba(0,0,0,.3); animation:opop .25s cubic-bezier(.2,.9,.3,1.2); }
@keyframes opop{ from{ opacity:0; transform:translateY(16px) scale(.97); } to{ opacity:1; transform:translateY(0) scale(1); } }
.oclose{ position:absolute; top:14px; right:14px; width:28px; height:28px; border:0; border-radius:50%;
  background:#f0e6db; color:var(--muted); cursor:pointer; font-size:13px; line-height:1; }
.oclose:hover{ background:#e7ddd2; }

.ohead{ display:flex; align-items:center; gap:14px; margin:6px 0 18px; }
.oemoji{ width:56px; height:56px; border-radius:16px; background:#fff0ea; display:flex; align-items:center; justify-content:center; font-size:32px; flex-shrink:0; }
.otitle{ font-size:18px; font-weight:800; }
.ometa{ font-size:13px; color:var(--muted); margin-top:3px; }

.orow{ display:flex; align-items:center; justify-content:space-between; gap:12px; margin-bottom:14px; }
.orow.col{ flex-direction:column; align-items:stretch; }
.olabel{ font-size:13.5px; font-weight:700; color:var(--muted); }
.stepper{ display:flex; align-items:center; gap:12px; }
.stepper button{ width:34px; height:34px; border:1.5px solid #ecdfd2; background:#fff; border-radius:10px; cursor:pointer;
  font-size:18px; line-height:1; color:var(--tomato); font-weight:700; }
.stepper button:hover{ border-color:var(--orange); }
.stepper span{ min-width:24px; text-align:center; font-weight:800; font-size:16px; }
.orow input{ width:100%; padding:11px 13px; border:1.5px solid #ecdfd2; border-radius:11px; font-size:14px;
  outline:none; font-family:inherit; }
.orow input:focus{ border-color:var(--orange); }

.obtn{ width:100%; border:0; border-radius:12px; padding:13px; font-weight:800; color:#fff; cursor:pointer; font-size:15px;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); box-shadow:0 8px 18px rgba(255,90,60,.3); transition:.2s; }
.obtn:hover{ filter:brightness(1.04); }
.otip{ margin-top:10px; text-align:center; font-size:11.5px; color:#b8a99a; }

.odone{ text-align:center; padding:10px 0 4px; }
.odone-emoji{ font-size:54px; }
.odone h3{ font-size:21px; font-weight:800; margin:8px 0 6px; }
.odone p{ font-size:14px; color:var(--muted); }
.odone-sub{ font-size:12px; color:#b8a99a; margin-top:4px; margin-bottom:16px; }
</style>
