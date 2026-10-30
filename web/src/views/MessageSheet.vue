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
  <div class="sheet">
    <div v-if="!msg" class="subtle">Ladataan…</div>
    <div v-else-if="msg.error" class="err">{{ msg.error }}</div>
    <template v-else>
      <div class="sheet-subj">{{ msg.subject }}</div>
      <div class="sheet-meta">{{ msg.from }} · {{ msg.timestamp }}</div>
      <div class="sheet-body" v-html="msg.html || ''"></div>

      <div v-for="(r, i) in msg.replies || []" :key="i" class="reply-box">
        <div class="sheet-meta">{{ r.from }} · {{ r.timestamp }}</div>
        <div class="sheet-body" v-html="r.html || ''"></div>
      </div>

      <div v-if="msg.allow_reply && !sent" class="reply-row">
        <input v-model="reply" class="field" placeholder="Vastaa…" @keydown.enter="sendReply" />
        <button class="send" :disabled="sending || !reply.trim()" @click="sendReply">
          <v-icon size="18">mdi-arrow-up</v-icon>
        </button>
      </div>
      <div v-if="sent" class="sent">Vastaus lähetetty.</div>
    </template>
  </div>
</template>

<style scoped>
.sheet {
  background: #0c0c0d;
  border-radius: 24px 24px 0 0;
  padding: 26px 22px 34px;
  max-height: 86vh;
  overflow-y: auto;
}
.sheet-subj {
  font-size: 21px;
  font-weight: 750;
  letter-spacing: -0.01em;
  line-height: 1.2;
}
.sheet-meta {
  color: #8e8e93;
  font-size: 13px;
  margin: 6px 0 18px;
}
.sheet-body {
  font-size: 15px;
  line-height: 1.55;
  color: #e2e2e6;
}
.sheet-body :deep(p) {
  margin: 0 0 10px;
}
.sheet-body :deep(a) {
  color: #7cb4ff;
}
.reply-box {
  margin-top: 16px;
  padding: 14px;
  border-radius: 14px;
  background: #141416;
}
.reply-row {
  display: flex;
  gap: 8px;
  margin-top: 22px;
}
.field {
  flex: 1;
  height: 46px;
  padding: 0 14px;
  border: 0;
  border-radius: 12px;
  background: #141416;
  color: #f2f2f7;
  font-size: 15px;
  outline: none;
}
.field::placeholder {
  color: #63636b;
}
.send {
  width: 46px;
  height: 46px;
  border: 0;
  border-radius: 12px;
  background: #fff;
  color: #000;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.send:disabled {
  opacity: 0.35;
}
.sent {
  color: #4ade80;
  font-size: 13.5px;
  margin-top: 18px;
}
.err {
  color: #ff6961;
  font-size: 13.5px;
}
.subtle {
  color: #8e8e93;
}
</style>
