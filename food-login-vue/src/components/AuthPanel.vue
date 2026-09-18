<script setup>
import { ref } from 'vue'
import { login, register } from '../composables/useAuth.js'

const emit = defineEmits(['logged-in'])

const tab = ref('login')            // 'login' | 'reg'

const lUser = ref('')
const lPwd = ref('')
const lRem = ref(false)
const lUserMsg = ref('')
const lPwdMsg = ref('')

const rUser = ref('')
const rPhone = ref('')
const rPwd = ref('')
const rUserMsg = ref('')
const rPhoneMsg = ref('')
const rPwdMsg = ref('')

const toastMsg = ref('')
let toastTimer = null
function showToast(m) {
  toastMsg.value = m
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => (toastMsg.value = ''), 2200)
}

function switchTab(t) {
  tab.value = t
  lUserMsg.value = lPwdMsg.value = ''
  rUserMsg.value = rPhoneMsg.value = rPwdMsg.value = ''
}

async function onLogin() {
  const username = lUser.value.trim()
  const password = lPwd.value
  if (!username) { lUserMsg.value = '请输入用户名'; return }
  if (!password) { lPwdMsg.value = '请输入密码'; return }
  lUserMsg.value = lPwdMsg.value = ''
  try {
    await login({ username, password })
    emit('logged-in', username)
  } catch (e) {
    lPwdMsg.value = e.message
  }
}

async function onReg() {
  const username = rUser.value.trim()
  const phone = rPhone.value.trim()
  const password = rPwd.value
  let ok = true
  if (username.length < 3) { rUserMsg.value = '用户名至少 3 个字符'; ok = false } else rUserMsg.value = ''
  if (!/^1\d{10}$/.test(phone)) { rPhoneMsg.value = '请输入有效的 11 位手机号'; ok = false } else rPhoneMsg.value = ''
  if (password.length < 6) { rPwdMsg.value = '密码至少 6 位'; ok = false } else rPwdMsg.value = ''
  if (!ok) return

  try {
    await register({ username, phone, password })
    showToast('🎉 注册成功，已自动登录')
    emit('logged-in', username)
  } catch (e) {
    if (/已存在/.test(e.message)) rUserMsg.value = e.message
    else rPwdMsg.value = e.message
  }
}
</script>

<template>
  <section class="panel">
    <div class="tabs">
      <button :class="{ active: tab === 'login' }" @click="switchTab('login')">登录</button>
      <button :class="{ active: tab === 'reg' }" @click="switchTab('reg')">注册</button>
    </div>

    <form v-show="tab === 'login'" @submit.prevent="onLogin">
      <div class="field">
        <label>用户名 / 手机号</label>
        <input v-model="lUser" placeholder="例如：吃货小王" autocomplete="username" />
        <div class="msg">{{ lUserMsg }}</div>
      </div>
      <div class="field">
        <label>密码</label>
        <input v-model="lPwd" type="password" placeholder="请输入密码" autocomplete="current-password" />
        <div class="msg">{{ lPwdMsg }}</div>
      </div>
      <div class="row">
        <label><input type="checkbox" v-model="lRem" /> 记住我</label>
        <a href="#">忘记密码？</a>
      </div>
      <button class="btn" type="submit">登录美食社区</button>
    </form>

    <form v-show="tab === 'reg'" @submit.prevent="onReg">
      <div class="field">
        <label>用户名</label>
        <input v-model="rUser" placeholder="至少 3 个字符" />
        <div class="msg">{{ rUserMsg }}</div>
      </div>
      <div class="field">
        <label>手机号</label>
        <input v-model="rPhone" placeholder="11 位手机号" />
        <div class="msg">{{ rPhoneMsg }}</div>
      </div>
      <div class="field">
        <label>密码</label>
        <input v-model="rPwd" type="password" placeholder="至少 6 位" />
        <div class="msg">{{ rPwdMsg }}</div>
      </div>
      <button class="btn" type="submit">创建账号</button>
    </form>

    <div class="or">或使用以下方式</div>
    <div class="social">
      <button type="button" @click="showToast('🍜 微信登录为演示功能')">💬 微信</button>
      <button type="button" @click="showToast('📱 手机号登录为演示功能')">📱 手机号</button>
    </div>

    <div class="toast" :class="{ show: toastMsg }">{{ toastMsg }}</div>
  </section>
</template>

<style scoped>
.panel{
  flex:1; padding:46px 40px; display:flex; flex-direction:column; justify-content:center;
  position:relative;
}
.tabs{
  display:flex; gap:8px; background:#f3ece4; padding:5px; border-radius:14px; margin-bottom:26px;
}
.tabs button{
  flex:1; border:0; background:transparent; padding:11px; border-radius:10px;
  font-size:15px; font-weight:600; color:var(--muted); cursor:pointer; transition:.2s;
}
.tabs button.active{ background:var(--card); color:var(--tomato); box-shadow:0 4px 14px rgba(0,0,0,.06); }

.field{ margin-bottom:16px; }
.field label{ display:block; font-size:13px; color:var(--muted); margin-bottom:7px; font-weight:600; }
.field input{
  width:100%; padding:13px 15px; border:1.5px solid #ecdfd2; border-radius:12px;
  font-size:15px; background:#fffdfb; transition:.2s; outline:none;
}
.field input:focus{ border-color:var(--orange); box-shadow:0 0 0 4px rgba(255,140,66,.15); }
.field .msg{ font-size:12px; margin-top:6px; min-height:14px; color:var(--err); }

.row{ display:flex; align-items:center; justify-content:space-between; margin:4px 0 22px; font-size:13px; }
.row label{ display:flex; align-items:center; gap:7px; color:var(--muted); cursor:pointer; }
.row a{ color:var(--orange); text-decoration:none; font-weight:600; }

.btn{
  width:100%; padding:14px; border:0; border-radius:13px; font-size:16px; font-weight:700;
  color:#fff; background:linear-gradient(120deg,var(--orange),var(--tomato)); cursor:pointer;
  box-shadow:0 10px 22px rgba(255,90,60,.35); transition:.2s;
}
.btn:hover{ transform:translateY(-2px); box-shadow:0 14px 28px rgba(255,90,60,.42); }
.btn:active{ transform:translateY(0); }

.or{ text-align:center; color:var(--muted); font-size:12.5px; margin:18px 0; position:relative; }
.or::before,.or::after{ content:""; position:absolute; top:50%; width:34%; height:1px; background:#ecdfd2; }
.or::before{ left:0; } .or::after{ right:0; }
.social{ display:flex; gap:12px; }
.social button{
  flex:1; display:flex; align-items:center; justify-content:center; gap:8px;
  padding:11px; border:1.5px solid #ecdfd2; border-radius:12px; background:#fff; cursor:pointer;
  font-size:14px; font-weight:600; color:var(--ink); transition:.2s;
}
.social button:hover{ border-color:var(--orange); background:#fffaf4; }
</style>
