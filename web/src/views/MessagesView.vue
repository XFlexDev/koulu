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
</script>

<template>
  <div class="pt-3 pb-24">
    <div class="d-flex align-center justify-space-between mb-4">
      <div class="text-h5 font-weight-bold">Viestit</div>
      <v-btn prepend-icon="mdi-pencil" variant="tonal" size="small" @click="compose = true">Uusi</v-btn>
    </div>

    <v-btn-toggle v-model="folder" mandatory divided class="w-100 mb-4" density="comfortable">
      <v-btn value="inbox" size="small" class="flex-1">Saapuneet</v-btn>
      <v-btn value="sent" size="small" class="flex-1">Lähetetyt</v-btn>
      <v-btn value="archive" size="small" class="flex-1">Arkisto</v-btn>
    </v-btn-toggle>

    <v-alert v-if="err" type="error" variant="tonal">{{ err }}</v-alert>
    <div v-if="!msgs && !err" class="text-medium-emphasis">Ladataan…</div>
    <v-card v-if="msgs?.length === 0" class="pa-4 text-medium-emphasis">Tyhjä.</v-card>

    <v-list bg-color="transparent" class="pa-0">
      <v-list-item v-for="m in msgs" :key="m.id" class="mb-2 rounded-lg border" @click="open = m.id">
        <template #prepend>
          <v-icon v-if="m.unread" color="blue-lighten-2" size="10">mdi-circle</v-icon>
          <div v-else style="width: 10px" />
        </template>
        <v-list-item-title :class="m.unread ? 'font-weight-bold' : 'font-weight-medium'">{{ m.subject }}</v-list-item-title>
        <v-list-item-subtitle>
          {{ m.from }} · {{ m.timestamp }}<template v-if="m.replies"> · {{ m.replies }} vastausta</template>
        </v-list-item-subtitle>
      </v-list-item>
    </v-list>

    <v-bottom-sheet :model-value="open !== null" @update:model-value="open = null">
      <MessageSheet v-if="open !== null" :id="open" />
    </v-bottom-sheet>
    <v-bottom-sheet v-model="compose">
      <ComposeSheet @sent="compose = false; folder = 'sent'" />
    </v-bottom-sheet>
  </div>
</template>
