<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue";
import { api } from "../api";
import type { Week, Day } from "../api";

const WD = ["Ma", "Ti", "Ke", "To", "Pe", "La", "Su"];

function mondayOf(d: Date) {
  const m = new Date(d);
  m.setDate(m.getDate() - ((m.getDay() + 6) % 7));
  return m.toISOString().slice(0, 10);
}

const anchor = ref(mondayOf(new Date()));
const week = ref<Week | null>(null);
const err = ref("");
const loading = ref(true);
const sel = ref(0);
const today = new Date().toISOString().slice(0, 10);

function load() {
  week.value = null;
  loading.value = true;
  api
    .schedule(anchor.value)
    .then((w) => {
      week.value = w;
      const ti = w.days.findIndex((d: Day) => d.date === today);
      sel.value = ti >= 0 ? ti : 0;
    })
    .catch((e) => (err.value = e.message))
    .finally(() => (loading.value = false));
}
onMounted(load);
watch(anchor, load);

function shift(days: number) {
  const d = new Date(anchor.value);
  d.setDate(d.getDate() + days);
  anchor.value = d.toISOString().slice(0, 10);
}

const weekNum = computed(() => {
  const s = week.value?.days[0]?.date;
  if (!s) return null;
  const d = new Date(s);
  const jan1 = new Date(d.getFullYear(), 0, 1);
  return Math.ceil(((d.getTime() - jan1.getTime()) / 86400000 + jan1.getDay() + 1) / 7);
});

const selDay = computed<Day | null>(() => week.value?.days[sel.value] || null);
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mt-4 mb-4">
      <div>
        <div class="text-h5 font-weight-bold">Viikko{{ weekNum ? ` ${weekNum}` : "" }}</div>
        <div class="text-caption text-medium-emphasis">
          {{ week?.week_start?.split("-").reverse().join(".") }}–{{ week?.week_end?.split("-").reverse().join(".") }}
        </div>
      </div>
      <div>
        <v-btn icon="mdi-chevron-left" variant="tonal" size="small" @click="shift(-7)" />
        <v-btn variant="tonal" size="small" class="mx-2" @click="anchor = mondayOf(new Date())">Nyt</v-btn>
        <v-btn icon="mdi-chevron-right" variant="tonal" size="small" @click="shift(7)" />
      </div>
    </div>

    <v-alert v-if="err" type="error" variant="tonal" class="mb-4">{{ err }}</v-alert>
    <v-progress-linear v-if="loading" indeterminate color="primary" class="mb-4" />

    <template v-if="week">
      <v-btn-toggle v-model="sel" mandatory color="primary" divided class="w-100 mb-5 daytoggle">
        <v-btn v-for="(d, i) in week.days.slice(0, 7)" :key="d.date" :value="i" class="flex-grow-1">
          <div class="d-flex flex-column align-center">
            <span class="text-caption">{{ WD[d.weekday - 1] }}</span>
            <span class="text-body-1 font-weight-bold">{{ new Date(d.date).getDate() }}</span>
          </div>
        </v-btn>
      </v-btn-toggle>

      <template v-if="selDay">
        <v-card v-if="selDay.lessons.length === 0" variant="tonal">
          <v-card-text class="text-center text-medium-emphasis py-8">Vapaapäivä.</v-card-text>
        </v-card>
        <v-list v-else bg-color="transparent" lines="two" density="comfortable" class="pa-0">
          <v-list-item v-for="(l, i) in selDay.lessons" :key="i" class="px-0" :style="l.break ? 'opacity: 0.4' : ''">
            <template #prepend>
              <v-avatar size="10" :color="l.break ? '#333' : l.color" class="mt-1" />
            </template>
            <v-list-item-title class="font-weight-medium">{{ l.subject }}</v-list-item-title>
            <v-list-item-subtitle>
              <span class="mono">{{ l.start }}–{{ l.end }}</span>
              <template v-if="l.room"> · {{ l.room }}</template>
              <template v-if="l.teachers.length"> · {{ l.teachers.join(", ") }}</template>
              <template v-if="l.info"> · {{ l.info }}</template>
            </v-list-item-subtitle>
          </v-list-item>
        </v-list>
      </template>
    </template>
  </div>
</template>

<style scoped>
.mono {
  font-variant-numeric: tabular-nums;
}
.daytoggle {
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px;
}
.daytoggle :deep(.v-btn) {
  min-width: 0;
}
</style>
