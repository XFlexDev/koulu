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
  <v-card rounded="t-xl" class="pb-6" style="max-height: 86vh; overflow-y: auto">
    <v-card-item v-if="!msg">
      <v-card-text class="text-medium-emphasis">Ladataan…</v-card-text>
    </v-card-item>
    <v-card-item v-else-if="msg.error">
      <v-alert type="error" variant="tonal">{{ msg.error }}</v-alert>
    </v-card-item>
    <template v-else>
      <v-card-item>
        <v-card-title style="white-space: normal">{{ msg.subject }}</v-card-title>
        <v-card-subtitle>{{ msg.from }} · {{ msg.timestamp }}</v-card-subtitle>
      </v-card-item>
      <v-card-text class="msg-body" v-html="msg.html || ''"></v-card-text>

      <v-card v-for="(r, i) in msg.replies || []" :key="i" variant="tonal" class="mx-4 mb-3">
        <v-card-subtitle class="pt-3">{{ r.from }} · {{ r.timestamp }}</v-card-subtitle>
        <v-card-text class="msg-body pt-1" v-html="r.html || ''"></v-card-text>
      </v-card>

      <v-card-item v-if="msg.allow_reply && !sent">
        <div class="d-flex ga-2">
          <v-text-field
            v-model="reply"
            placeholder="Vastaa…"
            density="compact"
            class="flex-grow-1"
            @keydown.enter="sendReply"
          />
          <v-btn icon="mdi-arrow-up" color="primary" :loading="sending" :disabled="!reply.trim()" @click="sendReply" />
        </div>
      </v-card-item>
      <v-card-item v-if="sent">
        <v-alert type="success" variant="tonal" density="compact">Vastaus lähetetty.</v-alert>
      </v-card-item>
    </template>
  </v-card>
</template>

<style scoped>
.msg-body {
  font-size: 15px;
  line-height: 1.55;
}
.msg-body :deep(p) {
  margin: 0 0 10px;
}
.msg-body :deep(a) {
  color: rgb(var(--v-theme-primary));
}
</style>
