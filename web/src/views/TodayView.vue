<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { api } from "../api";
import type { Week, Day, Lesson } from "../api";

const week = ref<Week | null>(null);
const err = ref("");
const loading = ref(true);

const todayStr = new Date().toISOString().slice(0, 10);
const nowMin = () => {
  const n = new Date();
  return n.getHours() * 60 + n.getMinutes();
};
const toMin = (t?: string) => {
  if (!t) return -1;
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
};

onMounted(() => {
  api
    .schedule(todayStr)
    .then((w) => (week.value = w))
    .catch((e) => (err.value = e.message))
    .finally(() => (loading.value = false));
});

const day = computed<Day | null>(() => week.value?.days.find((d) => d.date === todayStr) || null);

const n = nowMin();
const lessons = computed(() => day.value?.lessons || []);
const teach = computed(() => lessons.value.filter((l) => !l.break));
const current = computed(() => lessons.value.find((l) => !l.break && toMin(l.start) <= n && toMin(l.end) > n));
const next = computed(() => lessons.value.find((l) => !l.break && toMin(l.start) > n));
const done = computed(() => teach.value.length > 0 && !current.value && !next.value);

const dateLabel = new Date().toLocaleDateString("fi-FI", { weekday: "long", day: "numeric", month: "long" });

function progress(l: Lesson) {
  return Math.min(100, Math.max(0, ((n - toMin(l.start)) / (toMin(l.end) - toMin(l.start))) * 100));
}
</script>

<template>
  <div>
    <div class="text-h5 font-weight-bold text-capitalize mt-4 mb-4">{{ dateLabel }}</div>

    <v-alert v-if="err" type="error" variant="tonal" class="mb-4">{{ err }}</v-alert>
    <v-progress-linear v-if="loading" indeterminate color="primary" class="mb-4" />

    <template v-if="day">
      <v-card v-if="current" class="mb-5" variant="tonal">
        <v-card-item>
          <v-card-subtitle class="pa-0 mb-1">Nyt · klo {{ current.start }}–{{ current.end }}</v-card-subtitle>
          <v-card-title class="pa-0 text-h5 font-weight-bold" style="white-space: normal">
            {{ current.subject }}
          </v-card-title>
          <v-card-subtitle v-if="current.room || current.teachers[0]" class="pa-0 mt-1">
            <template v-if="current.room">{{ current.room }}</template>
            <template v-if="current.teachers[0]"> · {{ current.teachers[0] }}</template>
          </v-card-subtitle>
        </v-card-item>
        <v-progress-linear :model-value="progress(current)" :color="current.color" height="4" />
      </v-card>

      <v-card v-else-if="next && !done" class="mb-5" variant="tonal">
        <v-card-item>
          <v-card-subtitle class="pa-0 mb-1">Seuraavaksi · klo {{ next.start }}</v-card-subtitle>
          <v-card-title class="pa-0 text-h5 font-weight-bold" style="white-space: normal">{{ next.subject }}</v-card-title>
          <v-card-subtitle v-if="next.room" class="pa-0 mt-1">{{ next.room }}</v-card-subtitle>
        </v-card-item>
      </v-card>

      <v-card v-else-if="done" class="mb-5" variant="tonal">
        <v-card-title class="text-h6 font-weight-bold">Päivä ohi</v-card-title>
      </v-card>
      <v-card v-else-if="lessons.length === 0" class="mb-5" variant="tonal">
        <v-card-title class="text-h6 font-weight-bold">Ei tunteja tänään</v-card-title>
      </v-card>

      <v-list bg-color="transparent" lines="two" density="comfortable" class="pa-0">
        <v-list-item
          v-for="(l, i) in lessons"
          :key="i"
          class="px-0"
          :style="toMin(l.end) <= n || l.break ? 'opacity: 0.4' : ''"
        >
          <template #prepend>
            <v-avatar size="10" :color="l.break ? '#333' : l.color" class="mt-1" />
          </template>
          <v-list-item-title class="font-weight-medium">{{ l.subject }}</v-list-item-title>
          <v-list-item-subtitle>
            <span class="mono">{{ l.start }}–{{ l.end }}</span>
            <template v-if="l.room"> · {{ l.room }}</template>
            <template v-if="l.teachers.length"> · {{ l.teachers.join(", ") }}</template>
          </v-list-item-subtitle>
        </v-list-item>
      </v-list>
    </template>
  </div>
</template>

<style scoped>
.mono {
  font-variant-numeric: tabular-nums;
}
</style>
