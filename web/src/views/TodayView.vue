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
function inMin(l: Lesson) {
  return toMin(l.start) - n;
}
</script>

<template>
  <div>
    <div class="today-head">
      <div class="big-title text-capitalize">{{ dateLabel }}</div>
    </div>

    <div v-if="err" class="err-box">{{ err }}</div>
    <div v-if="!week && !err" class="subtle">Ladataan…</div>

    <template v-if="day">
      <!-- hero: now / next -->
      <div v-if="current" class="hero" :style="{ '--c': current.color }">
        <div class="hero-tag">Nyt</div>
        <div class="hero-subject">{{ current.subject }}</div>
        <div class="hero-meta mono-time">
          {{ current.start }}–{{ current.end }}<template v-if="current.room"> · {{ current.room }}</template
          ><template v-if="current.teachers[0]"> · {{ current.teachers[0] }}</template>
        </div>
        <div class="hero-bar"><div class="hero-bar-fill" :style="{ width: progress(current) + '%', background: current.color }" /></div>
        <div class="hero-left subtle">{{ toMin(current.end) - n }} min jäljellä</div>
      </div>

      <div v-else-if="next && !done" class="hero" :style="{ '--c': next.color }">
        <div class="hero-tag">Seuraavaksi</div>
        <div class="hero-subject">{{ next.subject }}</div>
        <div class="hero-meta mono-time">
          klo {{ next.start }}<template v-if="next.room"> · {{ next.room }}</template> · {{ inMin(next) }} min päästä
        </div>
      </div>

      <div v-else-if="done" class="hero hero-empty">
        <div class="hero-subject">Päivä ohi 🎉</div>
      </div>
      <div v-else-if="lessons.length === 0" class="hero hero-empty">
        <div class="hero-subject">Ei tunteja tänään</div>
      </div>

      <!-- timeline -->
      <div class="tl">
        <div
          v-for="(l, i) in lessons"
          :key="i"
          class="tl-row"
          :class="{ past: toMin(l.end) <= n, now: l === current, brk: l.break }"
        >
          <div class="tl-time mono-time">{{ l.start }}</div>
          <div class="tl-dot" :style="{ background: l.break ? '#2a2a2e' : l.color }" />
          <div class="tl-body">
            <div class="tl-subject">{{ l.subject }}</div>
            <div class="tl-meta subtle">
              <template v-if="l.room">{{ l.room }}</template>
              <template v-if="l.teachers[0]">{{ l.room ? " · " : "" }}{{ l.teachers[0] }}</template>
              <template v-if="l.info">{{ l.room || l.teachers[0] ? " · " : "" }}{{ l.info }}</template>
            </div>
          </div>
          <div class="tl-end mono-time subtle">{{ l.end }}</div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.today-head {
  margin: 14px 0 20px;
}
.err-box {
  background: #1a0d0d;
  color: #ff6961;
  border-radius: 14px;
  padding: 12px 14px;
  font-size: 13px;
  margin-bottom: 14px;
}

.hero {
  border-radius: 22px;
  padding: 20px 20px 18px;
  margin-bottom: 26px;
  background: linear-gradient(160deg, color-mix(in srgb, var(--c, #333) 16%, #0c0c0e), #0c0c0e 62%);
}
.hero-tag {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  color: color-mix(in srgb, var(--c, #999) 80%, #fff);
  margin-bottom: 8px;
}
.hero-subject {
  font-size: 26px;
  font-weight: 800;
  letter-spacing: -0.01em;
  line-height: 1.15;
}
.hero-meta {
  color: #b8b8bf;
  font-size: 14px;
  margin-top: 6px;
}
.hero-bar {
  height: 3px;
  border-radius: 99px;
  background: rgba(255, 255, 255, 0.09);
  margin-top: 16px;
  overflow: hidden;
}
.hero-bar-fill {
  height: 100%;
  border-radius: 99px;
}
.hero-left {
  font-size: 12px;
  margin-top: 7px;
}
.hero-empty {
  background: #0c0c0e;
}

.tl {
  position: relative;
}
.tl-row {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 10px 2px;
  border-bottom: 1px solid #141416;
}
.tl-row:last-child {
  border-bottom: 0;
}
.tl-time {
  width: 42px;
  padding-top: 2px;
  font-size: 13px;
  color: #b8b8bf;
  flex-shrink: 0;
}
.tl-dot {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  margin-top: 5px;
  flex-shrink: 0;
}
.tl-body {
  flex: 1;
  min-width: 0;
}
.tl-subject {
  font-size: 15px;
  font-weight: 650;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.tl-meta {
  font-size: 12.5px;
  margin-top: 1px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.tl-end {
  font-size: 13px;
  padding-top: 2px;
  flex-shrink: 0;
}
.tl-row.past {
  opacity: 0.32;
}
.tl-row.brk {
  opacity: 0.45;
}
.tl-row.now .tl-subject {
  color: #fff;
}
.tl-row.now .tl-time {
  color: #fff;
  font-weight: 700;
}
</style>
