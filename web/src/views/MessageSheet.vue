<script setup lang="ts">
import { onMounted, ref } from "vue";
import { api } from "../api";

const props = defineProps<{ id: number }>();
const msg = ref<any>(null);
const reply = ref("");
const sending = ref(false);
const sent = ref(false);

onMounted(async () => {
  try {
    msg.value = await api.message(props.id);
  } catch (e: any) {
    msg.value = { error: e.message };
  }
});

async function sendReply() {
  sending.value = true;
  try {
    await api.reply(props.id, reply.value);
    sent.value = true;
    reply.value = "";
  } catch (e: any) {
    alert(e.message);
  } finally {
    sending.value = false;
  }
}
</script>

<template>
  <v-card rounded="t-xl" color="#0c0c0d" class="pa-5" style="max-height: 88vh; overflow-y: auto">
    <div v-if="!msg" class="text-medium-emphasis">Ladataan…</div>
    <v-alert v-if="msg?.error" type="error" variant="tonal">{{ msg.error }}</v-alert>
    <template v-if="msg && !msg.error">
      <div class="text-h6">{{ msg.subject }}</div>
      <div class="text-caption text-medium-emphasis mt-1 mb-4">{{ msg.from }} · {{ msg.timestamp }}</div>
      <div class="msg-body" v-html="msg.html || msg.bbcode || ''"></div>
      <v-card v-for="(r, i) in msg.replies || []" :key="i" class="pa-4 mt-3">
        <div class="text-caption text-medium-emphasis mb-2">{{ r.from }} · {{ r.timestamp }}</div>
        <div class="msg-body" v-html="r.html || ''"></div>
      </v-card>
      <div v-if="msg.allow_reply && !sent" class="d-flex ga-2 mt-5">
        <v-text-field v-model="reply" placeholder="Vastaa…" class="flex-1" />
        <v-btn icon="mdi-send" color="white" class="text-black" :disabled="sending || !reply.trim()" @click="sendReply" />
      </div>
      <div v-if="sent" class="text-green text-body-2 mt-4">Vastaus lähetetty.</div>
    </template>
  </v-card>
</template>

<style>
.msg-body p {
  margin-bottom: 8px;
}
</style>
