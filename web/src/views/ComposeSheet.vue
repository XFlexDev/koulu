<script setup lang="ts">
import { onMounted, ref } from "vue";
import { api } from "../api";

const emit = defineEmits<{ sent: [] }>();
const recips = ref<any[]>([]);
const picked = ref<any[]>([]);
const subject = ref("");
const body = ref("");
const busy = ref(false);

onMounted(async () => {
  try {
    recips.value = (await api.recipients()).recipients;
  } catch {
    recips.value = [];
  }
});

async function send() {
  busy.value = true;
  try {
    await api.send(
      picked.value.map((p) => ({ id: String(p.id), type: p.type, n_class: p.n_class })),
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
  <v-card rounded="t-xl" class="pb-6" style="max-height: 90vh; overflow-y: auto">
    <v-card-item>
      <v-card-title>Uusi viesti</v-card-title>
    </v-card-item>
    <v-card-text class="d-flex flex-column ga-3">
      <v-autocomplete
        v-model="picked"
        :items="recips"
        item-title="name"
        label="Vastaanottajat"
        multiple
        chips
        closable-chips
        return-object
        :custom-filter="(t: string, q: string) => t.toLowerCase().includes(q.toLowerCase())"
      />
      <v-text-field v-model="subject" label="Aihe" />
      <v-textarea v-model="body" label="Viesti" rows="4" />
      <v-btn
        color="primary"
        size="large"
        block
        :loading="busy"
        :disabled="!picked.length || !subject.trim() || !body.trim()"
        @click="send"
      >
        Lähetä
      </v-btn>
    </v-card-text>
  </v-card>
</template>
