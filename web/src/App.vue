<script setup lang="ts">
import { ref } from "vue";
import { getToken, setToken } from "./api";
import LoginView from "./views/LoginView.vue";
import TodayView from "./views/TodayView.vue";
import WeekView from "./views/WeekView.vue";
import MessagesView from "./views/MessagesView.vue";
import MoreView from "./views/MoreView.vue";

const authed = ref(!!getToken());
const tab = ref("today");

function logout() {
  setToken(null);
  authed.value = false;
}
</script>

<template>
  <v-app>
    <LoginView v-if="!authed" @done="authed = true" />
    <template v-else>
      <v-main>
        <div class="page">
          <Transition name="fade" mode="out-in">
            <TodayView v-if="tab === 'today'" key="today" />
            <WeekView v-else-if="tab === 'week'" key="week" />
            <MessagesView v-else-if="tab === 'messages'" key="messages" />
            <MoreView v-else key="more" @logout="logout" />
          </Transition>
        </div>
      </v-main>
      <nav class="tabbar">
        <button
          v-for="t in [
            { id: 'today', label: 'Tänään', icon: 'mdi-clock-outline' },
            { id: 'week', label: 'Viikko', icon: 'mdi-calendar-week' },
            { id: 'messages', label: 'Viestit', icon: 'mdi-message-outline' },
            { id: 'more', label: 'Lisää', icon: 'mdi-dots-horizontal' },
          ]"
          :key="t.id"
          class="tabbar-btn"
          :class="{ active: tab === t.id }"
          @click="tab = t.id"
        >
          <v-icon size="21">{{ t.icon }}</v-icon>
          <span>{{ t.label }}</span>
        </button>
      </nav>
    </template>
  </v-app>
</template>

<style>
html,
body,
#app,
.v-application {
  background: #000 !important;
  color: #f2f2f7;
}

.page {
  max-width: 520px;
  margin: 0 auto;
  padding: 16px 16px 120px;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.18s ease, transform 0.18s ease;
}
.fade-enter-from {
  opacity: 0;
  transform: translateY(6px);
}
.fade-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}

/* floating pill tab bar */
.tabbar {
  position: fixed;
  bottom: 16px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 2px;
  padding: 6px;
  border-radius: 999px;
  background: rgba(18, 18, 20, 0.82);
  backdrop-filter: blur(24px) saturate(1.4);
  -webkit-backdrop-filter: blur(24px) saturate(1.4);
  border: 1px solid rgba(255, 255, 255, 0.07);
  z-index: 100;
}
.tabbar-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  min-width: 64px;
  padding: 7px 12px 6px;
  border: 0;
  border-radius: 999px;
  background: transparent;
  color: #77777d;
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.02em;
  cursor: pointer;
  transition: background 0.16s ease, color 0.16s ease;
}
.tabbar-btn.active {
  background: #26262b;
  color: #fff;
}

/* shared bits */
.big-title {
  font-size: 30px;
  font-weight: 800;
  letter-spacing: -0.02em;
  line-height: 1.1;
}
.subtle {
  color: #8e8e93;
}
.mono-time {
  font-variant-numeric: tabular-nums;
  font-feature-settings: "tnum";
}

.v-field--variant-solo-filled {
  --v-field-input-min-height: 48px;
}
.v-field--variant-solo-filled .v-field__overlay {
  background: #141416 !important;
}
.v-field--variant-solo-filled.v-field--focused .v-field__overlay {
  background: #1b1b1f !important;
}
.v-field__input {
  font-size: 15px;
}
</style>
