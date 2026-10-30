<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { api } from "../api";
import type { Week, Day, Lesson } from "../api";

const week = ref<Week | null>(null);
const err = ref("");

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
  api.schedule(todayStr).then((w) => (week.value = w)).catch((e) => (err.value = e.message));
});

const day = computed<Day | null>(() => {
  if (!week.value) return null;
  return week.value.days.find((d) => d.date === todayStr) || null;
});

const n = nowMin();
const lessons = computed(() => day.value?.lessons || []);
const current = computed(() => lessons.value.find((l) => toMin(l.start) <= n && toMin(l.end) > n));
const next = computed(() => lessons.value.find((l) => toMin(l.start) > n));
const done = computed(() => lessons.value.length > 0 && !current.value && !next.value);

const dateLabel = new Date().toLocaleDateString("fi-FI", { weekday: "long", day: "numeric", month: "numeric" });

function progress(l: Lesson) {
  return Math.min(100, Math.max(0, ((n - toMin(l.start)) / (toMin(l.end) - toMin(l.start))) * 100));
}
</script>

<template>
  <div class="pt-3 pb-24">
    <div class="text-h5 font-weight-bold text-capitalize mb-4">{{ dateLabel }}</div>

    <v-alert v-if="err" type="error" variant="tonal">{{ err }}</v-alert>
    <div v-if="!week && !err" class="text-medium-emphasis">Ladataan…</div>

    <template v-if="day">
      <v-card v-if="current" class="mb-3 overflow-hidden">
        <div class="d-flex">
          <div :style="{ width: '5px', background: current.color }" />
          <div class="pa-4 flex-1">
            <div class="text-overline text-medium-emphasis">Nyt</div>
            <div class="text-h6">{{ current.subject }}</div>
            <div class="text-body-2 text-medium-emphasis mt-1">
              {{ current.start }}–{{ current.end }}
              <template v-if="current.room"> · {{ current.room }}</template>
              <template v-if="current.teachers[0]"> · {{ current.teachers[0] }}</template>
            </div>
            <v-progress-linear :model-value="progress(current)" :color="current.color" class="mt-3" rounded />
            <div class="text-caption text-medium-emphasis mt-1">{{ toMin(current.end) - n }} min jäljellä</div>
          </div>
        </div>
      </v-card>

      <v-card v-else-if="next && !done" class="mb-3 overflow-hidden">
        <div class="d-flex">
          <div :style="{ width: '5px', background: next.color }" />
          <div class="pa-4 flex-1">
            <div class="text-overline text-medium-emphasis">Seuraavaksi</div>
            <div class="text-h6">{{ next.subject }}</div>
            <div class="text-body-2 text-medium-emphasis mt-1">
              klo {{ next.start }}<template v-if="next.room"> · {{ next.room }}</template> · {{ toMin(next.start) - n }} min päästä
            </div>
          </div>
        </div>
      </v-card>

      <v-card v-else-if="done" class="mb-3 pa-4 text-medium-emphasis">Päivä ohi. 🎉</v-card>
      <v-card v-else-if="lessons.length === 0" class="mb-3 pa-4 text-medium-emphasis">Ei tunteja tänään.</v-card>

      <v-card v-for="(l, i) in lessons" :key="i" class="mb-2" :class="{ 'opacity-40': toMin(l.end) <= n || l.break }">
        <div class="d-flex align-center pa-3 ga-3">
          <div :style="{ width: '4px', height: '40px', borderRadius: '2px', background: l.color }" />
          <div class="flex-1" style="min-width: 0">
            <div class="text-body-1 font-weight-medium text-truncate">{{ l.subject }}</div>
            <div class="text-caption text-medium-emphasis text-truncate">
              {{ l.room }}<template v-if="l.teachers[0]"> · {{ l.teachers[0] }}</template>
            </div>
          </div>
          <div class="text-body-2 text-medium-emphasis" style="font-variant-numeric: tabular-nums">{{ l.start }}–{{ l.end }}</div>
          <v-icon v-if="l === current" size="10" :color="l.color">mdi-circle</v-icon>
        </div>
      </v-card>
    </template>
  </div>
</template>
