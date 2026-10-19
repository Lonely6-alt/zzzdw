<script setup>
import { useRouter } from 'vue-router'
import AuthPanel from '../components/AuthPanel.vue'
import Hero from '../components/Hero.vue'

const router = useRouter()
function onLoggedIn() {
  router.push('/')
}
</script>

<template>
  <div class="auth-page">
    <div class="bg-orbs" aria-hidden="true">
      <span class="o1">🍜</span><span class="o2">🍣</span><span class="o3">🍔</span>
      <span class="o4">🍰</span><span class="o5">🥗</span><span class="o6">☕</span>
      <span class="o7">🍲</span><span class="o8">🍩</span>
    </div>
    <div class="app">
      <AuthPanel @logged-in="onLoggedIn" />
      <Hero />
    </div>
  </div>
</template>

<style scoped>
.auth-page{
  min-height:100vh; display:flex; align-items:center; justify-content:center; padding:20px;
  position:relative; overflow:hidden;
}
.bg-orbs{ position:absolute; inset:0; pointer-events:none; z-index:0; }
.bg-orbs span{ position:absolute; font-size:40px; opacity:.18; animation:orb 9s ease-in-out infinite; filter:blur(.3px); }
.o1{ left:6%;  top:18%; } .o2{ left:78%; top:12%; animation-delay:.8s; }
.o3{ left:14%; top:74%; animation-delay:1.6s; } .o4{ left:84%; top:70%; animation-delay:2.4s; }
.o5{ left:46%; top:8%;  animation-delay:3.2s; } .o6{ left:60%; top:84%; animation-delay:1.1s; }
.o7{ left:30%; top:40%; animation-delay:2.7s; font-size:54px; } .o8{ left:70%; top:46%; animation-delay:3.6s; }
@keyframes orb{
  0%,100%{ transform:translateY(0) rotate(-6deg); }
  50%{ transform:translateY(-22px) rotate(8deg); }
}
.app{ z-index:1; }
</style>
