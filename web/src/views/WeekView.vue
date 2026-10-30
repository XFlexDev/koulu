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
const sel = ref<string | null>(null);
const today = new Date().toISOString().slice(0, 10);

function load() {
  week.value = null;
  api.schedule(anchor.value).then((w) => (week.value = w)).catch((e) => (err.value = e.message));
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

const selDay = computed<Day | null>(() => {
  if (!week.value) return null;
  return (
    week.value.days.find((d) => d.date === sel.value) ||
    week.value.days.find((d) => d.date === today) ||
    week.value.days.find((d) => d.lessons.length) ||
    week.value.days[0]
  );
});
</script>

<template>
  <div class="pt-3 pb-24">
    <div class="d-flex align-center justify-space-between mb-4">
      <div class="text-h5 font-weight-bold">Viikko{{ weekNum ? ` ${weekNum}` : "" }}</div>
      <div class="d-flex ga-2">
        <v-btn icon="mdi-chevron-left" variant="tonal" size="small" @click="shift(-7)" />
        <v-btn variant="tonal" size="small" @click="anchor = mondayOf(new Date())">Nyt</v-btn>
        <v-btn icon="mdi-chevron-right" variant="tonal" size="small" @click="shift(7)" />
      </div>
    </div>

    <v-alert v-if="err" type="error" variant="tonal">{{ err }}</v-alert>
    <div v-if="!week && !err" class="text-medium-emphasis">Ladataan…</div>

    <template v-if="week">
      <div class="d-flex ga-1 overflow-x-auto pb-2 mb-4" style="margin: 0 -12px; padding: 0 12px">
        <v-card
          v-for="d in week.days.slice(0, 7)"
          :key="d.date"
          class="shrink-0 pa-2 d-flex flex-column ga-1"
          :variant="d.date === today ? 'outlined' : 'flat'"
          :color="d.date === today ? 'surface-bright' : 'surface'"
          style="width: 74px; min-height: 110px"
          @click="sel = d.date"
        >
          <div class="text-center">
            <div class="text-caption text-medium-emphasis">{{ WD[d.weekday - 1] }}</div>
            <div class="text-body-2 font-weight-medium">
              {{ new Date(d.date).getDate() }}.{{ new Date(d.date).getMonth() + 1 }}.
            </div>
          </div>
          <div
            v-for="(l, i) in d.lessons"
            :key="i"
            class="rounded px-1 py-1"
            :style="{ background: l.color + '22', borderLeft: `2px solid ${l.color}`, fontSize: '10px' }"
          >
            <div class="font-weight-medium text-truncate">{{ l.code || l.subject }}</div>
            <div class="text-medium-emphasis" style="font-variant-numeric: tabular-nums">{{ l.start }}</div>
          </div>
        </v-card>
      </div>

      <v-btn-group divided density="comfortable" class="w-100 mb-3" variant="flat">
        <v-btn
          v-for="d in week.days.slice(0, 7)"
          :key="d.date"
          size="small"
          class="flex-1"
          :color="selDay?.date === d.date ? 'white' : undefined"
          :class="selDay?.date === d.date ? 'text-black' : ''"
          @click="sel = d.date"
        >
          {{ WD[d.weekday - 1] }}
        </v-btn>
      </v-btn-group>

      <template v-if="selDay">
        <v-card v-if="selDay.lessons.length === 0" class="pa-4 text-medium-emphasis">Vapaapäivä.</v-card>
        <v-card v-for="(l, i) in selDay.lessons" :key="i" class="mb-2 pa-4">
          <div class="d-flex justify-space-between ga-3">
            <div style="min-width: 0">
              <div class="text-body-1 font-weight-medium">{{ l.subject }}</div>
              <div class="text-caption text-medium-emphasis mt-1">
                {{ l.room }}
                <template v-if="l.teachers.length"> · {{ l.teachers.join(", ") }}</template>
                <template v-if="l.class"> · {{ l.class }}</template>
              </div>
              <div v-if="l.info" class="text-caption text-medium-emphasis mt-1">{{ l.info }}</div>
            </div>
            <div class="text-body-2 text-medium-emphasis flex-shrink-0" style="font-variant-numeric: tabular-nums">
              {{ l.start }}–{{ l.end }}
            </div>
          </div>
          <div class="mt-3 rounded-pill" :style="{ height: '2px', background: l.color }" />
        </v-card>
      </template>
    </template>
  </div>
</template>
