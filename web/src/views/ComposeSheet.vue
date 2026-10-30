<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { api } from "../api";

const emit = defineEmits<{ sent: [] }>();
const recips = ref<any[] | null>(null);
const picked = ref<any[]>([]);
const subject = ref("");
const body = ref("");
const busy = ref(false);
const q = ref("");

onMounted(async () => {
  try {
    recips.value = (await api.recipients()).recipients;
  } catch {
    recips.value = [];
  }
});

const filtered = computed(() =>
  (recips.value || []).filter((r) => r.name.toLowerCase().includes(q.value.toLowerCase()))
);

async function send() {
  busy.value = true;
  try {
    await api.send(
      picked.value.map((p) => ({ id: String(p.id), type: p.type })),
      subject.value,
      body.value
    );
    emit("sent");
  } catch (e: any) {
    alert(e.message);
  } finally {
    busy.value = false;
  }
}
</script>

<template>
  <v-card rounded="t-xl" color="#0c0c0d" class="pa-5" style="max-height: 90vh; overflow-y: auto">
    <div class="text-h6 mb-4">Uusi viesti</div>
    <v-text-field v-model="q" placeholder="Hae vastaanottajaa…" class="mb-2" />
    <div v-if="picked.length" class="d-flex flex-wrap ga-1 mb-2">
      <v-chip
        v-for="p in picked"
        :key="p.type + '-' + p.id"
        closable
        size="small"
        @click:close="picked = picked.filter((x) => x !== p)"
      >
        {{ p.name }}
      </v-chip>
    </div>
    <div style="max-height: 160px; overflow-y: auto" class="mb-3">
      <v-list bg-color="transparent" density="compact" class="pa-0">
        <v-list-item
          v-for="r in filtered.slice(0, 40)"
          :key="r.type + '-' + r.id"
          class="rounded mb-1 border"
          @click="!picked.includes(r) && picked.push(r)"
        >
          <v-list-item-title class="text-body-2">
            {{ r.name }} <span class="text-caption text-medium-emphasis">{{ r.type }}</span>
          </v-list-item-title>
        </v-list-item>
      </v-list>
    </div>
    <v-text-field v-model="subject" placeholder="Aihe" class="mb-2" />
    <v-textarea v-model="body" placeholder="Viesti…" rows="4" class="mb-3" />
    <v-btn
      block
      size="large"
      color="white"
      class="text-black font-weight-bold"
      :loading="busy"
      :disabled="!picked.length || !subject.trim() || !body.trim()"
      @click="send"
    >
      Lähetä
    </v-btn>
  </v-card>
</template>
