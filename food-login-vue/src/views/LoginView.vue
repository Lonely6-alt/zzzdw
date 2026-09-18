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
    <div class="app">
      <AuthPanel @logged-in="onLoggedIn" />
      <Hero />
    </div>
  </div>
</template>

<style scoped>
.auth-page{
  min-height:100vh; display:flex; align-items:center; justify-content:center; padding:20px;
}
</style>
