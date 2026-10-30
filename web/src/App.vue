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
        <v-container style="max-width: 560px" class="pb-24">
          <TodayView v-if="tab === 'today'" />
          <WeekView v-else-if="tab === 'week'" />
          <MessagesView v-else-if="tab === 'messages'" />
          <MoreView v-else @logout="logout" />
        </v-container>
      </v-main>
      <v-bottom-navigation v-model="tab" grow color="primary" bg-color="#0c0c0e" elevation="0" border="t">
        <v-btn value="today">
          <v-icon>mdi-clock-outline</v-icon>
          <span>Tänään</span>
        </v-btn>
        <v-btn value="week">
          <v-icon>mdi-calendar-week</v-icon>
          <span>Viikko</span>
        </v-btn>
        <v-btn value="messages">
          <v-icon>mdi-message-outline</v-icon>
          <span>Viestit</span>
        </v-btn>
        <v-btn value="more">
          <v-icon>mdi-dots-horizontal</v-icon>
          <span>Lisää</span>
        </v-btn>
      </v-bottom-navigation>
    </template>
  </v-app>
</template>

<style>
html,
body,
#app,
.v-application {
  background: #000 !important;
}
</style>
