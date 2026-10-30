<script setup lang="ts">
import { ref, watch } from "vue";
import { api } from "../api";
import MessageSheet from "./MessageSheet.vue";
import ComposeSheet from "./ComposeSheet.vue";

interface Msg {
  id: number;
  subject: string;
  from: string;
  timestamp: string;
  unread: boolean;
  replies: number;
}

const folder = ref("inbox");
const msgs = ref<Msg[] | null>(null);
const err = ref("");
const open = ref<number | null>(null);
const compose = ref(false);

function load() {
  msgs.value = null;
  api.messages(folder.value).then((d) => (msgs.value = d.messages)).catch((e) => (err.value = e.message));
}
watch(folder, load);
load();

const folders = [
  { id: "inbox", label: "Saapuneet" },
  { id: "sent", label: "Lähetetyt" },
  { id: "archive", label: "Arkisto" },
];
</script>

<template>
  <div>
    <div class="msg-head">
      <div class="big-title">Viestit</div>
      <button class="fab" @click="compose = true"><v-icon size="20">mdi-pencil</v-icon></button>
    </div>

    <div class="seg">
      <button
        v-for="f in folders"
        :key="f.id"
        class="seg-btn"
        :class="{ sel: folder === f.id }"
        @click="folder = f.id"
      >
        {{ f.label }}
      </button>
    </div>

    <div v-if="err" class="err-box">{{ err }}</div>
    <div v-if="!msgs && !err" class="subtle">Ladataan…</div>
    <div v-if="msgs?.length === 0" class="empty subtle">Tyhjä.</div>

    <div class="mlist">
      <button v-for="m in msgs" :key="m.id" class="mrow" @click="open = m.id">
        <span class="mrow-dot" :class="{ unread: m.unread }" />
        <span class="mrow-main">
          <span class="mrow-subj" :class="{ bold: m.unread }">{{ m.subject }}</span>
          <span class="mrow-meta">{{ m.from }}<template v-if="m.replies"> · {{ m.replies }} vastausta</template></span>
        </span>
        <span class="mrow-time">{{ (m.timestamp || "").slice(5, 10).replace("-", ".") }}</span>
      </button>
    </div>

    <v-bottom-sheet :model-value="open !== null" @update:model-value="open = null">
      <MessageSheet v-if="open !== null" :id="open" />
    </v-bottom-sheet>
    <v-bottom-sheet v-model="compose">
      <ComposeSheet @sent="compose = false; folder = 'sent'" />
    </v-bottom-sheet>
  </div>
</template>

<style scoped>
.msg-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin: 14px 0 16px;
}
.fab {
  width: 40px;
  height: 40px;
  border: 0;
  border-radius: 50%;
  background: #fff;
  color: #000;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.fab:active {
  transform: scale(0.94);
}

.seg {
  display: flex;
  background: #141416;
  border-radius: 12px;
  padding: 3px;
  margin-bottom: 18px;
}
.seg-btn {
  flex: 1;
  border: 0;
  background: transparent;
  color: #8e8e93;
  font-size: 13px;
  font-weight: 600;
  padding: 8px 0;
  border-radius: 9px;
  cursor: pointer;
  transition: background 0.15s ease, color 0.15s ease;
}
.seg-btn.sel {
  background: #2a2a2f;
  color: #fff;
}

.mlist {
  display: flex;
  flex-direction: column;
}
.mrow {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 13px 2px;
  border: 0;
  border-bottom: 1px solid #141416;
  background: transparent;
  text-align: left;
  cursor: pointer;
  color: inherit;
  width: 100%;
}
.mrow:last-child {
  border-bottom: 0;
}
.mrow-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-top: 6px;
  flex-shrink: 0;
  background: transparent;
}
.mrow-dot.unread {
  background: #4c9fff;
}
.mrow-main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}
.mrow-subj {
  font-size: 15px;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.mrow-subj.bold {
  font-weight: 750;
}
.mrow-meta {
  font-size: 12.5px;
  color: #8e8e93;
  margin-top: 1px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.mrow-time {
  font-size: 12px;
  color: #8e8e93;
  padding-top: 3px;
  flex-shrink: 0;
}

.err-box {
  background: #1a0d0d;
  color: #ff6961;
  border-radius: 14px;
  padding: 12px 14px;
  font-size: 13px;
  margin-bottom: 14px;
}
.empty {
  padding: 40px 0;
  text-align: center;
  font-size: 14px;
}
</style>
