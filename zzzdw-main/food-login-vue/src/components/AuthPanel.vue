<script setup>
import { ref, computed, onMounted } from 'vue'
import { login, register, fetchCaptcha } from '../composables/useAuth.js'

const emit = defineEmits(['logged-in'])

const tab = ref('login')            // 'login' | 'reg'

/* ---------- 登录 ---------- */
const lUser = ref('')
const lPwd = ref('')
const lRem = ref(false)
const lShow = ref(false)
const lUserMsg = ref('')
const lPwdMsg = ref('')

/* ---------- 注册 ---------- */
const rUser = ref('')
const rPwd = ref('')
const rPwd2 = ref('')
const rCaptcha = ref('')
const rShow = ref(false)
const rUserMsg = ref('')
const rPwdMsg = ref('')
const rPwd2Msg = ref('')
const rCaptchaMsg = ref('')

/* ---------- 图片验证码 ---------- */
const captchaId = ref('')
const captchaImg = ref('')

/* ---------- 密码长度 / 强度可视化 ---------- */
const pwdLen = computed(() => rPwd.value.length)
const pwdPct = computed(() => Math.min(100, Math.round((rPwd.value.length / 8) * 100)))
const pwdOk = computed(() => rPwd.value.length === 8)

const toastMsg = ref('')
let toastTimer = null
function showToast(m) {
  toastMsg.value = m
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => (toastMsg.value = ''), 2600)
}

function switchTab(t) {
  tab.value = t
  lUserMsg.value = lPwdMsg.value = ''
  rUserMsg.value = rPwdMsg.value = rPwd2Msg.value = rCaptchaMsg.value = ''
  if (t === 'reg') refreshCaptcha()
}

async function refreshCaptcha() {
  try {
    const d = await fetchCaptcha()
    captchaId.value = d.id
    captchaImg.value = d.image
    rCaptchaMsg.value = ''
  } catch (e) {
    rCaptchaMsg.value = e.message
  }
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
  const password = rPwd.value
  let ok = true
  if (username.length < 3) { rUserMsg.value = '用户名至少 3 个字符'; ok = false } else rUserMsg.value = ''
  if (password.length !== 8) { rPwdMsg.value = '密码必须为 8 位'; ok = false } else rPwdMsg.value = ''
  if (rPwd2.value !== password) { rPwd2Msg.value = '两次输入的密码不一致'; ok = false } else rPwd2Msg.value = ''
  if (!rCaptcha.value.trim()) { rCaptchaMsg.value = '请输入图片中的验证码'; ok = false } else rCaptchaMsg.value = ''
  if (!ok) return

  try {
    await register({ username, password, captchaId: captchaId.value, captcha: rCaptcha.value.trim() })
    showToast('🎉 注册成功，已自动登录')
    emit('logged-in', username)
  } catch (e) {
    if (/已存在/.test(e.message)) rUserMsg.value = e.message
    else if (/验证码/.test(e.message)) { rCaptchaMsg.value = e.message; refreshCaptcha() }
    else rPwdMsg.value = e.message
  }
}

onMounted(() => { if (tab.value === 'reg') refreshCaptcha() })
</script>

<template>
  <section class="panel">
    <span class="spark s1">🍅</span>
    <span class="spark s2">🥕</span>
    <span class="spark s3">🌶️</span>

    <div class="tabs">
      <button :class="{ active: tab === 'login' }" @click="switchTab('login')">登录</button>
      <button :class="{ active: tab === 'reg' }" @click="switchTab('reg')">注册</button>
      <i class="slider" :class="tab"></i>
    </div>

    <!-- 登录 -->
    <form v-show="tab === 'login'" @submit.prevent="onLogin" class="flip">
      <div class="field">
        <label>用户名</label>
        <div class="input-wrap">
          <span class="ic">👤</span>
          <input v-model="lUser" placeholder="例如：吃货小王" autocomplete="username" />
        </div>
        <div class="msg">{{ lUserMsg }}</div>
      </div>
      <div class="field">
        <label>密码</label>
        <div class="input-wrap">
          <span class="ic">🔒</span>
          <input v-model="lPwd" :type="lShow ? 'text' : 'password'" placeholder="请输入密码" autocomplete="current-password" />
          <span class="eye" @click="lShow = !lShow">{{ lShow ? '🙈' : '👁️' }}</span>
        </div>
        <div class="msg">{{ lPwdMsg }}</div>
      </div>
      <div class="row">
        <label><input type="checkbox" v-model="lRem" /> 记住我</label>
        <a href="#">忘记密码？</a>
      </div>
      <button class="btn" type="submit"><span>登录美食社区</span></button>
    </form>

    <!-- 注册 -->
    <form v-show="tab === 'reg'" @submit.prevent="onReg" class="flip">
      <div class="field">
        <label>用户名</label>
        <div class="input-wrap">
          <span class="ic">👤</span>
          <input v-model="rUser" placeholder="至少 3 个字符" autocomplete="username" />
        </div>
        <div class="msg">{{ rUserMsg }}</div>
      </div>
      <div class="field">
        <label>密码 <span class="hint">需为 8 位</span></label>
        <div class="input-wrap">
          <span class="ic">🔒</span>
          <input v-model="rPwd" :type="rShow ? 'text' : 'password'" placeholder="请输入 8 位密码" maxlength="8" inputmode="text" />
          <span class="eye" @click="rShow = !rShow">{{ rShow ? '🙈' : '👁️' }}</span>
        </div>
        <div class="meter"><i :style="{ width: pwdPct + '%' }" :class="{ ok: pwdOk }"></i></div>
        <div class="msg">{{ rPwdMsg || (pwdLen ? pwdLen + ' / 8' : '') }}</div>
      </div>
      <div class="field">
        <label>确认密码</label>
        <div class="input-wrap">
          <span class="ic">🔒</span>
          <input v-model="rPwd2" :type="rShow ? 'text' : 'password'" placeholder="再次输入密码" maxlength="8" />
        </div>
        <div class="msg">{{ rPwd2Msg }}</div>
      </div>
      <div class="field">
        <label>图片验证码 <span class="hint">点击图片可刷新</span></label>
        <div class="code-row">
          <div class="input-wrap grow">
            <span class="ic">🖼️</span>
            <input v-model="rCaptcha" placeholder="请输入图中字符" maxlength="4" autocomplete="off" autocapitalize="off" spellcheck="false" />
          </div>
          <img v-if="captchaImg" class="captcha-img" :src="captchaImg" alt="图片验证码" title="看不清？点击刷新" @click="refreshCaptcha" />
          <button v-else type="button" class="code-btn" @click="refreshCaptcha">加载中…</button>
        </div>
        <div class="msg">{{ rCaptchaMsg }}</div>
      </div>
      <button class="btn" type="submit"><span>🎉 创建账号</span></button>
    </form>

    <div class="or">或使用以下方式</div>
    <div class="social">
      <button type="button" @click="showToast('🍜 微信登录为演示功能')">💬 微信</button>
    </div>

    <div class="toast" :class="{ show: toastMsg }">{{ toastMsg }}</div>
  </section>
</template>

<style scoped>
.panel{
  flex:1; padding:42px 40px 30px; display:flex; flex-direction:column; justify-content:center;
  position:relative; overflow:hidden;
}
.panel::after{ /* 玻璃质感背景光晕 */
  content:""; position:absolute; width:280px; height:280px; right:-90px; top:-90px;
  background:radial-gradient(circle,rgba(255,140,66,.18),transparent 70%); pointer-events:none;
}

.spark{ position:absolute; font-size:22px; opacity:.5; animation:drift 7s ease-in-out infinite; pointer-events:none; }
.s1{ left:14px; bottom:18px; animation-delay:0s; }
.s2{ right:18px; bottom:60px; animation-delay:1.6s; }
.s3{ left:40%; top:14px; animation-delay:3s; }
@keyframes drift{ 0%,100%{ transform:translateY(0) rotate(-8deg); } 50%{ transform:translateY(-12px) rotate(10deg); } }

.tabs{ position:relative; display:flex; gap:8px; background:#f3ece4; padding:5px; border-radius:14px; margin-bottom:24px; }
.tabs button{
  flex:1; position:relative; z-index:2; border:0; background:transparent; padding:11px; border-radius:10px;
  font-size:15px; font-weight:600; color:var(--muted); cursor:pointer; transition:.25s;
}
.tabs button.active{ color:var(--tomato); }
.slider{ position:absolute; z-index:1; top:5px; bottom:5px; width:calc(50% - 5px); border-radius:10px;
  background:var(--card); box-shadow:0 4px 14px rgba(0,0,0,.07); transition:.3s cubic-bezier(.4,0,.2,1); }
.slider.reg{ left:5px; transform:translateX(100%); }

.flip{ animation:flipIn .35s ease; }
@keyframes flipIn{ from{ opacity:0; transform:translateY(8px); } to{ opacity:1; transform:translateY(0); } }

.field{ margin-bottom:14px; }
.field label{ display:block; font-size:13px; color:var(--muted); margin-bottom:7px; font-weight:600; }
.field .hint{ color:var(--orange); font-weight:700; }
.input-wrap{ position:relative; display:flex; align-items:center;
  border:1.5px solid #ecdfd2; border-radius:12px; background:#fffdfb; transition:.2s; }
.input-wrap:focus-within{ border-color:var(--orange); box-shadow:0 0 0 4px rgba(255,140,66,.15); }
.input-wrap .ic{ padding-left:13px; font-size:15px; opacity:.7; }
.input-wrap input{ flex:1; width:100%; padding:12px 14px; border:0; outline:none; background:transparent;
  font-size:15px; border-radius:12px; }
.input-wrap .eye{ padding:0 12px; cursor:pointer; user-select:none; font-size:15px; opacity:.7; }
.input-wrap .eye:hover{ opacity:1; }
.field .msg{ font-size:12px; margin-top:5px; min-height:14px; color:var(--err); }

.meter{ height:5px; border-radius:6px; background:#f0e6db; overflow:hidden; margin-top:7px; }
.meter i{ display:block; height:100%; width:0; border-radius:6px;
  background:linear-gradient(90deg,#ffb347,#ff5a3c); transition:width .25s ease; }
.meter i.ok{ background:linear-gradient(90deg,#34d27b,#2e9e5b); }

.code-row{ display:flex; gap:10px; align-items:stretch; }
.code-row .grow{ flex:1; }
.captcha-img{ height:44px; width:130px; border:1.5px solid #ecdfd2; border-radius:12px; cursor:pointer;
  background:#fff; flex:0 0 auto; display:block; }
.code-btn{ white-space:nowrap; padding:0 16px; border:0; border-radius:12px; cursor:pointer;
  font-size:13.5px; font-weight:700; color:#fff; background:linear-gradient(120deg,#ffb347,#ff8c42);
  transition:.2s; }
.code-btn:hover:not(:disabled){ filter:brightness(1.05); }
.code-btn:disabled{ background:#e7ddd2; color:var(--muted); cursor:not-allowed; }

.row{ display:flex; align-items:center; justify-content:space-between; margin:2px 0 20px; font-size:13px; }
.row label{ display:flex; align-items:center; gap:7px; color:var(--muted); cursor:pointer; }
.row a{ color:var(--orange); text-decoration:none; font-weight:600; }

.btn{ position:relative; overflow:hidden; width:100%; padding:14px; border:0; border-radius:13px;
  font-size:16px; font-weight:700; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,var(--orange),var(--tomato));
  box-shadow:0 10px 22px rgba(255,90,60,.35); transition:.2s; }
.btn::before{ content:""; position:absolute; top:0; left:-120%; width:60%; height:100%;
  background:linear-gradient(120deg,transparent,rgba(255,255,255,.45),transparent);
  transform:skewX(-20deg); animation:shine 3s infinite; }
.btn:hover{ transform:translateY(-2px); box-shadow:0 14px 28px rgba(255,90,60,.42); }
.btn:active{ transform:translateY(0); }
@keyframes shine{ 0%{ left:-120%; } 60%,100%{ left:140%; } }

.or{ text-align:center; color:var(--muted); font-size:12.5px; margin:16px 0; position:relative; }
.or::before,.or::after{ content:""; position:absolute; top:50%; width:34%; height:1px; background:#ecdfd2; }
.or::before{ left:0; } .or::after{ right:0; }
.social{ display:flex; gap:12px; }
.social button{ flex:1; display:flex; align-items:center; justify-content:center; gap:8px;
  padding:11px; border:1.5px solid #ecdfd2; border-radius:12px; background:#fff; cursor:pointer;
  font-size:14px; font-weight:600; color:var(--ink); transition:.2s; }
.social button:hover{ border-color:var(--orange); background:#fffaf4; }
</style>
