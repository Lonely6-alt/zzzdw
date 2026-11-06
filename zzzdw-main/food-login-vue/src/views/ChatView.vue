<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getToken } from '../composables/useAuth.js'
import { useToast } from '../composables/useToast.js'

const route = useRoute()
const router = useRouter()
const { toast } = useToast()

const sessions = ref([])        // 私聊会话
const groups = ref([])          // 群聊
const activeType = ref('')      // 'private' | 'group'
const activeId = ref(null)
const activePeer = ref({ id: null, name: '' })
const activeGroup = ref(null)   // { groupId, groupName, emoji, notice, members: [] }
const messages = ref([])
const draft = ref('')
const loading = ref(false)
const err = ref('')
const bubbleBox = ref(null)
const myId = ref(null)
const wsStatus = ref('offline') // connecting | online | offline

// 新建群聊弹窗
const showGroupModal = ref(false)
const contacts = ref([])
const groupForm = ref({ groupName: '', emoji: '👥', memberIds: [] })
const creating = ref(false)
const GROUP_EMOJIS = ['👥', '🍜', '🍲', '🍣', '🍰', '☕', '🔥', '🌙']

const API = '/api/chat'
function h(extra = {}) {
  return { 'Content-Type': 'application/json', Authorization: `Bearer ${getToken()}`, ...extra }
}

/* ---------------- 数据加载 ---------------- */
async function loadMe() {
  try {
    const r = await fetch('/api/me', { headers: h() })
    if (r.ok) {
      const d = await r.json()
      myId.value = d.user?.id ?? null
    }
  } catch { /* 忽略 */ }
}

async function loadSessions() {
  try {
    const r = await fetch(`${API}/sessions`, { headers: h() })
    if (!r.ok) throw new Error('加载会话失败')
    sessions.value = await r.json()
  } catch (e) { err.value = e.message }
}

async function loadGroups() {
  try {
    const r = await fetch(`${API}/groups`, { headers: h() })
    if (!r.ok) return
    groups.value = await r.json()
  } catch { /* 静默 */ }
}

async function loadContacts() {
  try {
    const r = await fetch(`${API}/contacts`, { headers: h() })
    if (r.ok) contacts.value = await r.json()
  } catch { /* 静默 */ }
}

/* ---------------- 会话切换 ---------------- */
async function openSession(id, peerId, peerName) {
  activeType.value = 'private'
  activeId.value = id
  activePeer.value = { id: peerId, name: peerName }
  activeGroup.value = null
  messages.value = []
  await loadMessages()
  const s = sessions.value.find(x => Number(x.sessionId) === Number(id))
  if (s) s.unread = 0
}

async function openGroup(g) {
  activeType.value = 'group'
  activeId.value = g.groupId
  activeGroup.value = { ...g, members: [] }
  activePeer.value = { id: null, name: '' }
  messages.value = []
  await loadGroupDetail(g.groupId)
  await loadMessages()
  const item = groups.value.find(x => Number(x.groupId) === Number(g.groupId))
  if (item) item.unread = 0
}

async function loadGroupDetail(groupId) {
  try {
    const r = await fetch(`${API}/groups/${groupId}`, { headers: h() })
    if (r.ok) {
      const d = await r.json()
      activeGroup.value = { ...(activeGroup.value || {}), ...d }
    }
  } catch { /* 静默 */ }
}

async function loadMessages(silent = false) {
  if (!activeId.value || !activeType.value) return
  try {
    const url = activeType.value === 'private'
      ? `${API}/sessions/${activeId.value}/messages`
      : `${API}/groups/${activeId.value}/messages`
    const r = await fetch(url, { headers: h() })
    if (!r.ok) return
    const fresh = await r.json()
    const changed = fresh.length !== messages.value.length ||
      (fresh.length && messages.value.length &&
        fresh[fresh.length - 1].msgId !== messages.value[messages.value.length - 1].msgId)
    messages.value = fresh
    if (changed) nextTick(scrollBottom)
    if (activeType.value === 'private' && fresh.length) {
      const s = sessions.value.find(x => Number(x.sessionId) === Number(activeId.value))
      if (s) {
        s.lastMsg = fresh[fresh.length - 1].content
        s.lastTime = fresh[fresh.length - 1].sendTime
      }
    } else if (activeType.value === 'group' && fresh.length) {
      const g = groups.value.find(x => Number(x.groupId) === Number(activeId.value))
      if (g) {
        g.lastMsg = fresh[fresh.length - 1].content
        g.lastTime = fresh[fresh.length - 1].sendTime
      }
    }
  } catch { if (!silent) { /* 静默轮询 */ } }
}

async function openByPeerName(name) {
  if (!name) return
  loading.value = true
  try {
    const r = await fetch(`${API}/sessions`, {
      method: 'POST', headers: h(),
      body: JSON.stringify({ peerUsername: name })
    })
    const d = await r.json().catch(() => ({}))
    if (!r.ok) throw new Error(d.message || '打开会话失败')
    await loadSessions()
    openSession(d.sessionId, d.peerId, d.peerName)
  } catch (e) { err.value = e.message }
  finally { loading.value = false }
}

/* ---------------- 发送 ---------------- */
async function send() {
  const content = draft.value.trim()
  if (!content || !activeId.value) return
  const type = activeType.value
  const id = activeId.value
  draft.value = ''
  try {
    const url = type === 'private'
      ? `${API}/sessions/${id}/messages`
      : `${API}/groups/${id}/messages`
    const r = await fetch(url, { method: 'POST', headers: h(), body: JSON.stringify({ content }) })
    const d = await r.json().catch(() => ({}))
    if (!r.ok) throw new Error(d.message || '发送失败')
    // WebSocket 会把消息推回来（已去重），这里兜底立即刷新
    if (type === 'private') {
      const msg = { ...d }
      mergeMessage(msg)
    } else {
      mergeMessage(d)
    }
    loadMessages(true)
  } catch (e) {
    draft.value = content
    toast(e.message, 'error')
  }
}

function mergeMessage(m) {
  if (!m || m.msgId == null) return
  if (messages.value.some(x => Number(x.msgId) === Number(m.msgId))) return
  messages.value.push(m)
  nextTick(scrollBottom)
}

function scrollBottom() {
  const el = bubbleBox.value
  if (el) el.scrollTop = el.scrollHeight
}

/* ---------------- 群聊创建 ---------------- */
async function openGroupModal() {
  groupForm.value = { groupName: '', emoji: '👥', memberIds: [] }
  showGroupModal.value = true
  if (!contacts.value.length) await loadContacts()
}
function closeGroupModal() { showGroupModal.value = false }

async function createGroup() {
  const name = groupForm.value.groupName.trim()
  if (name.length < 2) { toast('群名称至少 2 个字', 'error'); return }
  if (!groupForm.value.memberIds.length) { toast('至少选一位群成员', 'error'); return }
  creating.value = true
  try {
    const r = await fetch(`${API}/groups`, {
      method: 'POST', headers: h(),
      body: JSON.stringify({
        groupName: name,
        emoji: groupForm.value.emoji,
        memberIds: groupForm.value.memberIds
      })
    })
    const d = await r.json().catch(() => ({}))
    if (!r.ok) throw new Error(d.message || '创建失败')
    showGroupModal.value = false
    await loadGroups()
    const g = groups.value.find(x => Number(x.groupId) === Number(d.groupId))
    if (g) openGroup(g)
    toast('群聊已创建', 'success')
  } catch (e) {
    toast(e.message, 'error')
  } finally {
    creating.value = false
  }
}

/* ---------------- WebSocket 实时通信 ---------------- */
let ws = null
let reconnectTimer = null
let pingTimer = null
let alive = true

function wsUrl() {
  const proto = location.protocol === 'https:' ? 'wss' : 'ws'
  const token = encodeURIComponent(getToken() || '')
  return `${proto}://${location.host}/ws/chat?token=${token}`
}

function connectWs() {
  if (!alive || !getToken()) return
  wsStatus.value = 'connecting'
  try {
    ws = new WebSocket(wsUrl())
  } catch {
    wsStatus.value = 'offline'
    return
  }
  ws.onopen = () => {
    wsStatus.value = 'online'
    clearInterval(pingTimer)
    pingTimer = setInterval(() => {
      if (ws && ws.readyState === 1) ws.send('ping')
    }, 25000)
  }
  ws.onmessage = (e) => {
    let d
    try { d = JSON.parse(e.data) } catch { return }
    handleWsEvent(d)
  }
  ws.onclose = () => {
    wsStatus.value = 'offline'
    clearInterval(pingTimer)
    if (alive) {
      clearTimeout(reconnectTimer)
      reconnectTimer = setTimeout(connectWs, 4000)
    }
  }
  ws.onerror = () => { /* onclose 会负责重连 */ }
}

let readTimer = null
function handleWsEvent(d) {
  if (!d || d.type === 'pong') return

  if (d.type === 'private' && d.msg) {
    const m = d.msg
    const sameChat = activeType.value === 'private' && Number(activeId.value) === Number(d.sessionId)
    if (sameChat) {
      mergeMessage(m)
      clearTimeout(readTimer)
      readTimer = setTimeout(() => loadMessages(true), 300)
    } else if (Number(m.senderId) !== Number(myId.value)) {
      const s = sessions.value.find(x => Number(x.sessionId) === Number(d.sessionId))
      if (s) {
        s.lastMsg = m.content
        s.lastTime = m.sendTime
        s.unread = (s.unread || 0) + 1
      } else {
        loadSessions()
      }
    }
    return
  }

  if (d.type === 'group' && d.msg) {
    const m = d.msg
    const sameChat = activeType.value === 'group' && Number(activeId.value) === Number(d.groupId)
    if (sameChat) {
      mergeMessage(m)
      // 正在看这个群，立即把已读位往后推
      clearTimeout(readTimer)
      readTimer = setTimeout(() => loadMessages(true), 300)
    } else if (Number(m.senderId) !== Number(myId.value)) {
      const g = groups.value.find(x => Number(x.groupId) === Number(d.groupId))
      if (g) {
        g.lastMsg = m.content
        g.lastTime = m.sendTime
        g.unread = (g.unread || 0) + 1
      } else {
        loadGroups()
      }
    }
    return
  }

  if (d.type === 'group_members') {
    if (activeType.value === 'group' && Number(activeId.value) === Number(d.groupId)) {
      loadGroupDetail(activeId.value)
    }
  }
}

/* ---------------- 展示辅助 ---------------- */
function fmtTime(t) {
  if (!t) return ''
  return String(t).replace('T', ' ').slice(5, 16)
}
function shortTime(t) {
  return t ? String(t).replace('T', ' ').slice(11, 16) : ''
}
function isMine(m) {
  if (activeType.value === 'group') {
    return Number(m.senderId) === Number(myId.value)
  }
  return Number(m.senderId) !== Number(activePeer.value.id)
}
const wsText = computed(() => ({
  online: '实时在线',
  connecting: '连接中…',
  offline: '重连中…'
}[wsStatus.value] || '实时在线'))

let listTimer = null
let msgTimer = null

onMounted(async () => {
  await loadMe()
  await loadSessions()
  await loadGroups()
  connectWs()

  // 路由参数：/chat?peer=xxx 打开私聊，/chat?group=1 打开群聊
  const peer = route.query.peer
  const gid = route.query.group
  if (peer) openByPeerName(String(peer))
  else if (gid) {
    const g = groups.value.find(x => Number(x.groupId) === Number(gid))
    if (g) openGroup(g)
  }

  // 轮询作为兜底（WebSocket 断开时仍能收到消息）
  listTimer = setInterval(() => { loadSessions(); loadGroups() }, 12000)
  msgTimer = setInterval(() => loadMessages(true), 8000)
})

onBeforeUnmount(() => {
  alive = false
  clearInterval(listTimer)
  clearInterval(msgTimer)
  clearInterval(pingTimer)
  clearTimeout(reconnectTimer)
  clearTimeout(readTimer)
  if (ws) {
    try { ws.close() } catch { /* 忽略 */ }
  }
})

const hasAnyChat = computed(() => sessions.value.length > 0 || groups.value.length > 0)
</script>

<template>
  <div class="chat-page">
    <div class="chat-shell">
      <!-- 会话列表：私聊 / 群聊分区展示 -->
      <aside class="chat-side">
        <div class="side-head">
          <span>💬 消息</span>
          <button class="new-group" type="button" @click="openGroupModal">＋ 群聊</button>
        </div>

        <div class="side-scroll">
          <div class="side-cat">私聊<span class="cat-count">{{ sessions.length }}</span></div>
          <ul class="s-list">
            <li
              v-for="s in sessions"
              :key="'p' + s.sessionId"
              :class="{ on: activeType === 'private' && Number(s.sessionId) === Number(activeId) }"
              @click="openSession(s.sessionId, s.peerId, s.peerName)"
            >
              <span class="s-avatar">{{ (s.peerName || '?')[0] }}</span>
              <div class="s-main">
                <div class="s-top">
                  <span class="s-name">@{{ s.peerName }}</span>
                  <span class="s-time">{{ shortTime(s.lastTime) }}</span>
                </div>
                <div class="s-msg">{{ s.lastMsg || '开始聊天吧～' }}</div>
              </div>
              <span v-if="s.unread > 0" class="s-dot">{{ s.unread > 99 ? '99+' : s.unread }}</span>
            </li>
            <li v-if="!sessions.length" class="s-empty">
              还没有私聊<br />去帖子卡片点作者昵称发起第一句吧
            </li>
          </ul>

          <div class="side-cat">群聊<span class="cat-count">{{ groups.length }}</span></div>
          <ul class="s-list">
            <li
              v-for="g in groups"
              :key="'g' + g.groupId"
              :class="{ on: activeType === 'group' && Number(g.groupId) === Number(activeId) }"
              @click="openGroup(g)"
            >
              <span class="s-avatar group">{{ g.emoji || '👥' }}</span>
              <div class="s-main">
                <div class="s-top">
                  <span class="s-name">{{ g.groupName }}</span>
                  <span class="s-time">{{ shortTime(g.lastTime) }}</span>
                </div>
                <div class="s-msg">{{ g.lastMsg || `${g.memberCount} 位成员` }}</div>
              </div>
              <span v-if="g.unread > 0" class="s-dot">{{ g.unread > 99 ? '99+' : g.unread }}</span>
            </li>
            <li v-if="!groups.length" class="s-empty">
              还没有群聊<br />点右上角「＋ 群聊」拉上朋友一起聊
            </li>
          </ul>
        </div>
      </aside>

      <!-- 聊天窗口 -->
      <section class="chat-main">
        <template v-if="activeId">
          <div class="c-head">
            <button class="back" @click="router.push('/')">‹ 返回首页</button>
            <div class="c-title">
              <span class="c-peer">
                {{ activeType === 'group'
                  ? `${activeGroup?.emoji || '👥'} ${activeGroup?.groupName || ''}`
                  : `与 @${activePeer.name} 聊天` }}
              </span>
              <span v-if="activeType === 'group'" class="c-sub">
                {{ activeGroup?.members?.length || 0 }} 位成员
              </span>
            </div>
            <span class="c-live" :class="{ off: wsStatus !== 'online' }"><i></i>{{ wsText }}</span>
          </div>
          <div class="c-box" ref="bubbleBox">
            <div
              v-for="m in messages"
              :key="m.msgId"
              class="row"
              :class="{ mine: isMine(m) }"
            >
              <div class="bubble" :class="{ mine: isMine(m) }">
                <span v-if="activeType === 'group' && !isMine(m)" class="b-name">{{ m.senderName }}</span>
                <p class="b-text">{{ m.content }}</p>
                <span class="b-time">{{ fmtTime(m.sendTime) }}</span>
              </div>
            </div>
            <div v-if="!messages.length" class="c-empty">
              {{ activeType === 'group' ? '群里还很安静，先说一句吧 👋' : '打个招呼吧 👋' }}
            </div>
          </div>
          <div class="c-input">
            <input
              v-model="draft"
              type="text"
              :placeholder="activeType === 'group' ? `发消息到「${activeGroup?.groupName || ''}」…` : '输入消息，回车发送…'"
              maxlength="1000"
              @keydown.enter="send"
            />
            <button :disabled="!draft.trim()" @click="send">发送</button>
          </div>
        </template>
        <div v-else class="c-placeholder">
          <span class="p-emoji">{{ hasAnyChat ? '💬' : '👥' }}</span>
          <p>{{ hasAnyChat ? '选择左侧会话继续聊天' : '选择左侧会话，或点右上角「＋ 群聊」新建一个群' }}</p>
        </div>
      </section>
    </div>

    <p v-if="err" class="chat-err">{{ err }}</p>

    <!-- 新建群聊 -->
    <div v-if="showGroupModal" class="modal-mask" @click.self="closeGroupModal">
      <div class="modal">
        <h3>新建群聊</h3>
        <p class="modal-tip">给群起个名字，再勾选要拉进来的朋友</p>

        <label class="m-field">
          <span>群名称</span>
          <input v-model="groupForm.groupName" maxlength="30" placeholder="例如：周末探店小分队" />
        </label>

        <div class="m-field">
          <span>群图标</span>
          <div class="m-emojis">
            <button
              v-for="e in GROUP_EMOJIS" :key="e" type="button" class="m-emoji"
              :class="{ on: groupForm.emoji === e }" @click="groupForm.emoji = e"
            >{{ e }}</button>
          </div>
        </div>

        <div class="m-field">
          <span>群成员（{{ groupForm.memberIds.length }} 已选）</span>
          <div class="m-members">
            <label v-for="c in contacts" :key="c.id" class="m-member">
              <input type="checkbox" :value="c.id" v-model="groupForm.memberIds" />
              <span class="m-avatar">{{ (c.username || '?')[0] }}</span>
              <span class="m-name">@{{ c.username }}</span>
            </label>
            <p v-if="!contacts.length" class="m-empty">暂无可邀请的用户</p>
          </div>
        </div>

        <div class="m-actions">
          <button class="m-btn ghost" type="button" @click="closeGroupModal">取消</button>
          <button class="m-btn primary" type="button" :disabled="creating" @click="createGroup">
            {{ creating ? '创建中…' : '创建群聊' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.chat-page{ max-width:1040px; margin:0 auto; padding:20px 24px 60px; }
.chat-shell{ display:flex; height:calc(100vh - 190px); min-height:460px; background:#fff;
  border:1.5px solid #f0e6db; border-radius:20px; overflow:hidden; box-shadow:0 12px 30px rgba(255,90,60,.08); }

/* 左侧会话列表 */
.chat-side{ width:280px; flex-shrink:0; border-right:1.5px solid #f0e6db; background:#fffaf4; display:flex; flex-direction:column; }
.side-head{ padding:13px 14px; font-size:15px; font-weight:800; color:#7e5a3e; border-bottom:1.5px solid #f0e6db;
  display:flex; align-items:center; justify-content:space-between; gap:8px; }
.new-group{ border:none; border-radius:999px; padding:5px 12px; font-size:12px; font-weight:700; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,#ff9a52,#ff5f3d); font-family:inherit; transition:.2s; white-space:nowrap; }
.new-group:hover{ transform:translateY(-1px); box-shadow:0 6px 12px rgba(255,90,60,.28); }
.side-scroll{ flex:1; overflow-y:auto; }
.side-cat{ display:flex; align-items:center; gap:6px; padding:9px 16px 4px; font-size:11.5px; font-weight:800;
  color:#b99b82; letter-spacing:.4px; }
.cat-count{ background:#f1e4d7; color:#9a8270; border-radius:999px; padding:0 7px; font-size:10.5px; }
.s-list{ list-style:none; margin:0; padding:4px 8px 8px; }
.s-list li{ display:flex; align-items:center; gap:10px; padding:10px; border-radius:12px; cursor:pointer; transition:.2s; position:relative; }
.s-list li:hover{ background:#fff0e4; }
.s-list li.on{ background:#ffe9d8; }
.s-avatar{ width:38px; height:38px; flex-shrink:0; border-radius:50%; display:flex; align-items:center; justify-content:center;
  background:linear-gradient(135deg,#ffb26b,#ff5f3d); color:#fff; font-weight:800; font-size:16px; }
.s-avatar.group{ background:linear-gradient(135deg,#8ec5ff,#5c8df6); font-size:19px; }
.s-main{ flex:1; min-width:0; }
.s-top{ display:flex; justify-content:space-between; align-items:baseline; gap:6px; }
.s-name{ font-size:13.5px; font-weight:700; color:#4a3526; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.s-time{ font-size:11px; color:#b99b82; flex-shrink:0; }
.s-msg{ font-size:12px; color:#9a8270; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; margin-top:2px; }
.s-dot{ position:absolute; right:10px; top:8px; min-width:18px; height:18px; padding:0 5px; border-radius:9px;
  background:#ff3b30; color:#fff; font-size:11px; font-weight:800; display:flex; align-items:center; justify-content:center; }
.s-empty{ text-align:center; color:#b99b82; font-size:12px; padding:16px 16px 20px; line-height:1.9; cursor:default; }

/* 右侧聊天窗口 */
.chat-main{ flex:1; min-width:0; display:flex; flex-direction:column; }
.c-head{ display:flex; align-items:center; gap:12px; padding:12px 16px; border-bottom:1.5px solid #f0e6db; }
.back{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted,#8a7a6a); border-radius:999px; padding:5px 12px;
  font-size:12.5px; cursor:pointer; transition:.2s; font-family:inherit; flex-shrink:0; }
.back:hover{ border-color:var(--orange,#ff9a52); color:var(--tomato,#ff5f3d); }
.c-title{ flex:1; min-width:0; display:flex; align-items:baseline; gap:8px; }
.c-peer{ font-size:14.5px; font-weight:800; color:#4a3526; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.c-sub{ font-size:11.5px; color:#a08b78; flex-shrink:0; }
.c-live{ font-size:11.5px; color:#2f9a5d; display:flex; align-items:center; gap:5px; flex-shrink:0; }
.c-live i{ width:7px; height:7px; border-radius:50%; background:#2f9a5d; animation:pulse 1.6s infinite; }
.c-live.off{ color:#b99b82; }
.c-live.off i{ background:#d9c7b4; }
@keyframes pulse{ 0%,100%{ opacity:1; } 50%{ opacity:.35; } }

.c-box{ flex:1; overflow-y:auto; padding:18px 20px; background:#fffaf4; }
.row{ display:flex; margin-bottom:14px; }
.row.mine{ justify-content:flex-end; }
.bubble{ max-width:72%; background:#fff; border:1.5px solid #f0e6db; border-radius:14px 14px 14px 4px; padding:9px 13px; }
.row .bubble{ margin-right:auto; }
.bubble.mine{ background:linear-gradient(130deg,#ff9a52,#ff5f3d); color:#fff; border:none; border-radius:14px 14px 4px 14px; margin-left:auto; }
.b-name{ display:block; font-size:11.5px; font-weight:800; color:#b4652f; margin-bottom:3px; }
.b-text{ margin:0; font-size:14px; line-height:1.6; word-break:break-word; white-space:pre-wrap; }
.b-time{ display:block; font-size:10.5px; opacity:.6; margin-top:4px; }
.c-empty{ text-align:center; color:#c4ab94; font-size:13px; padding-top:60px; }

.c-input{ display:flex; gap:10px; padding:12px 16px; border-top:1.5px solid #f0e6db; background:#fff; }
.c-input input{ flex:1; border:1.5px solid #ecdfd2; border-radius:999px; padding:10px 16px; font-size:14px; outline:none;
  transition:border-color .2s; font-family:inherit; }
.c-input input:focus{ border-color:var(--orange,#ff9a52); }
.c-input button{ border:none; border-radius:999px; padding:10px 22px; font-size:14px; font-weight:800; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,#ff9a52,#ff5f3d); transition:.2s; font-family:inherit; }
.c-input button:disabled{ opacity:.45; cursor:not-allowed; }
.c-input button:not(:disabled):hover{ transform:translateY(-1px); box-shadow:0 6px 14px rgba(255,90,60,.3); }

.c-placeholder{ flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; color:#c4ab94; gap:10px; }
.p-emoji{ font-size:52px; }
.chat-err{ color:#d64541; font-size:13px; text-align:center; margin-top:10px; }

/* 新建群聊弹窗 */
.modal-mask{ position:fixed; inset:0; background:rgba(58,38,24,.42); backdrop-filter:blur(2px); z-index:60;
  display:flex; align-items:center; justify-content:center; padding:20px; }
.modal{ width:100%; max-width:430px; background:#fff; border-radius:20px; padding:20px 22px;
  box-shadow:0 24px 60px rgba(58,38,24,.28); max-height:86vh; overflow-y:auto; }
.modal h3{ margin:0 0 4px; font-size:17px; color:#3b2a1d; }
.modal-tip{ margin:0 0 14px; font-size:12.5px; color:#a08b78; }
.m-field{ display:block; margin-bottom:13px; }
.m-field > span{ display:block; font-size:12.5px; font-weight:700; color:#7e5a3e; margin-bottom:7px; }
.m-field input{ width:100%; box-sizing:border-box; border:1.5px solid #ecdfd2; border-radius:12px; padding:9px 13px;
  font-size:14px; font-family:inherit; outline:none; color:#4a3526; }
.m-field input:focus{ border-color:var(--orange,#ff9a52); }
.m-emojis{ display:flex; flex-wrap:wrap; gap:7px; }
.m-emoji{ width:36px; height:36px; border-radius:11px; border:1.5px solid #f0e6db; background:#fff; font-size:17px; cursor:pointer; transition:.2s; }
.m-emoji.on{ border-color:var(--tomato,#ff5f3d); background:#fff2ea; }
.m-members{ max-height:190px; overflow-y:auto; display:flex; flex-direction:column; gap:4px;
  border:1.5px solid #f4e9dd; border-radius:14px; padding:8px; }
.m-member{ display:flex; align-items:center; gap:8px; padding:6px 6px; border-radius:10px; cursor:pointer; }
.m-member:hover{ background:#fff6ee; }
.m-avatar{ width:26px; height:26px; border-radius:50%; background:linear-gradient(135deg,#ffb26b,#ff5f3d); color:#fff;
  font-size:12px; font-weight:800; display:flex; align-items:center; justify-content:center; }
.m-name{ font-size:13px; color:#4a3526; }
.m-empty{ font-size:12.5px; color:#b99b82; text-align:center; padding:14px 0; margin:0; }
.m-actions{ display:flex; gap:10px; margin-top:16px; }
.m-btn{ flex:1; border-radius:12px; padding:10px; font-size:14px; font-weight:800; cursor:pointer; font-family:inherit; transition:.2s; }
.m-btn.ghost{ background:#fff; border:1.5px solid #ecdfd2; color:#8a7a6a; }
.m-btn.primary{ border:none; color:#fff; background:linear-gradient(120deg,#ff9a52,#ff5f3d); box-shadow:0 8px 18px rgba(255,90,60,.24); }
.m-btn.primary:disabled{ opacity:.55; cursor:not-allowed; }

@media (max-width:720px){
  .chat-shell{ flex-direction:column; height:auto; }
  .chat-side{ width:100%; max-height:300px; border-right:none; border-bottom:1.5px solid #f0e6db; }
  .chat-main{ min-height:420px; }
}
</style>
