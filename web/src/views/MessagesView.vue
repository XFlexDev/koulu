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
const loading = ref(true);
const open = ref<number | null>(null);
const compose = ref(false);

function load() {
  msgs.value = null;
  loading.value = true;
  api
    .messages(folder.value)
    .then((d) => (msgs.value = d.messages))
    .catch((e) => (err.value = e.message))
    .finally(() => (loading.value = false));
}
watch(folder, load);
load();
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mt-4 mb-3">
      <div class="text-h5 font-weight-bold">Viestit</div>
      <v-btn icon="mdi-pencil" color="primary" @click="compose = true" />
    </div>

    <v-tabs v-model="folder" color="primary" class="mb-3" density="comfortable">
      <v-tab value="inbox">Saapuneet</v-tab>
      <v-tab value="sent">Lähetetyt</v-tab>
      <v-tab value="archive">Arkisto</v-tab>
    </v-tabs>

    <v-alert v-if="err" type="error" variant="tonal" class="mb-4">{{ err }}</v-alert>
    <v-progress-linear v-if="loading" indeterminate color="primary" class="mb-4" />

    <v-card v-if="msgs?.length === 0" variant="tonal">
      <v-card-text class="text-center text-medium-emphasis py-8">Tyhjä.</v-card-text>
    </v-card>

    <v-list v-if="msgs?.length" bg-color="transparent" lines="two" class="pa-0">
      <v-list-item v-for="m in msgs" :key="m.id" class="px-0" @click="open = m.id">
        <template #prepend>
          <v-badge v-if="m.unread" dot color="primary" inline />
        </template>
        <v-list-item-title :class="m.unread ? 'font-weight-bold' : 'font-weight-medium'">{{ m.subject }}</v-list-item-title>
        <v-list-item-subtitle>
          {{ m.from }}<template v-if="m.replies"> · {{ m.replies }} vastausta</template>
        </v-list-item-subtitle>
        <template #append>
          <span class="text-caption text-medium-emphasis">{{ (m.timestamp || "").slice(5, 10).replace("-", ".") }}</span>
        </template>
      </v-list-item>
      <v-divider />
    </v-list>

    <v-bottom-sheet :model-value="open !== null" @update:model-value="open = null">
      <MessageSheet v-if="open !== null" :id="open" />
    </v-bottom-sheet>
    <v-bottom-sheet v-model="compose">
      <ComposeSheet @sent="compose = false; folder = 'sent'" />
    </v-bottom-sheet>
  </div>
</template>
