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
  <div class="sheet">
    <div class="sheet-title">Uusi viesti</div>

    <input v-model="q" class="field" placeholder="Hae vastaanottajaa…" />
    <div v-if="picked.length" class="picked">
      <button v-for="p in picked" :key="p.type + '-' + p.id" class="chip" @click="picked = picked.filter((x) => x !== p)">
        {{ p.name }} <v-icon size="14">mdi-close</v-icon>
      </button>
    </div>
    <div class="recip-list">
      <button
        v-for="r in filtered.slice(0, 40)"
        :key="r.type + '-' + r.id + '-' + (r.n_class || '')"
        class="recip"
        @click="!picked.includes(r) && picked.push(r)"
      >
        {{ r.name }} <span class="rtype">{{ r.type }}</span>
      </button>
    </div>

    <input v-model="subject" class="field" placeholder="Aihe" />
    <textarea v-model="body" class="field area" rows="4" placeholder="Viesti…" />
    <button class="send-btn" :disabled="busy || !picked.length || !subject.trim() || !body.trim()" @click="send">
      {{ busy ? "Lähetetään…" : "Lähetä" }}
    </button>
  </div>
</template>

<style scoped>
.sheet {
  background: #0c0c0d;
  border-radius: 24px 24px 0 0;
  padding: 26px 22px 34px;
  max-height: 90vh;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.sheet-title {
  font-size: 21px;
  font-weight: 750;
  margin-bottom: 8px;
}
.field {
  width: 100%;
  min-height: 46px;
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
.field.area {
  padding-top: 12px;
  resize: none;
}
.picked {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.chip {
  border: 0;
  background: #26262b;
  color: #e8e8ec;
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 12.5px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  cursor: pointer;
}
.recip-list {
  max-height: 170px;
  overflow-y: auto;
  border-radius: 12px;
  background: #101012;
}
.recip {
  display: block;
  width: 100%;
  border: 0;
  border-bottom: 1px solid #1a1a1d;
  background: transparent;
  color: #e8e8ec;
  text-align: left;
  padding: 11px 14px;
  font-size: 14px;
  cursor: pointer;
}
.recip:last-child {
  border-bottom: 0;
}
.rtype {
  color: #63636b;
  font-size: 12px;
}
.send-btn {
  height: 48px;
  border: 0;
  border-radius: 12px;
  background: #fff;
  color: #000;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
}
.send-btn:disabled {
  opacity: 0.35;
}
</style>
