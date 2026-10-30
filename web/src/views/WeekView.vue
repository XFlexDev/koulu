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
    week.value.days[0]
  );
});
</script>

<template>
  <div>
    <div class="wk-head">
      <div>
        <div class="big-title">Viikko{{ weekNum ? ` ${weekNum}` : "" }}</div>
        <div class="subtle" style="font-size: 13px; margin-top: 2px">
          {{ week?.week_start?.split("-").reverse().join(".") }} – {{ week?.week_end?.split("-").reverse().join(".") }}
        </div>
      </div>
      <div class="wk-nav">
        <button class="navb" @click="shift(-7)"><v-icon size="18">mdi-chevron-left</v-icon></button>
        <button class="navb" @click="anchor = mondayOf(new Date())">Nyt</button>
        <button class="navb" @click="shift(7)"><v-icon size="18">mdi-chevron-right</v-icon></button>
      </div>
    </div>

    <div v-if="err" class="err-box">{{ err }}</div>
    <div v-if="!week && !err" class="subtle">Ladataan…</div>

    <template v-if="week">
      <div class="dayrow">
        <button
          v-for="d in week.days.slice(0, 7)"
          :key="d.date"
          class="daypill"
          :class="{ sel: selDay?.date === d.date, today: d.date === today }"
          @click="sel = d.date"
        >
          <span class="daypill-wd">{{ WD[d.weekday - 1] }}</span>
          <span class="daypill-num">{{ new Date(d.date).getDate() }}</span>
          <span class="daypill-dots">
            <i v-for="(l, i) in d.lessons.filter((x) => !x.break).slice(0, 4)" :key="i" :style="{ background: l.color }" />
          </span>
        </button>
      </div>

      <template v-if="selDay">
        <div v-if="selDay.lessons.length === 0" class="empty-day subtle">Vapaapäivä.</div>
        <div v-else class="tl">
          <div v-for="(l, i) in selDay.lessons" :key="i" class="tl-row" :class="{ brk: l.break }">
            <div class="tl-time mono-time">{{ l.start }}</div>
            <div class="tl-dot" :style="{ background: l.break ? '#2a2a2e' : l.color }" />
            <div class="tl-body">
              <div class="tl-subject">{{ l.subject }}</div>
              <div class="tl-meta subtle">
                <template v-if="l.room">{{ l.room }}</template>
                <template v-if="l.teachers.length">{{ l.room ? " · " : "" }}{{ l.teachers.join(", ") }}</template>
                <template v-if="l.info">{{ l.room || l.teachers.length ? " · " : "" }}{{ l.info }}</template>
              </div>
            </div>
            <div class="tl-end mono-time subtle">{{ l.end }}</div>
          </div>
        </div>
      </template>
    </template>
  </div>
</template>

<style scoped>
.wk-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin: 14px 0 20px;
}
.wk-nav {
  display: flex;
  gap: 6px;
  margin-top: 4px;
}
.navb {
  height: 34px;
  min-width: 34px;
  padding: 0 10px;
  border: 0;
  border-radius: 999px;
  background: #161618;
  color: #e8e8ec;
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
.navb:active {
  transform: scale(0.96);
}
.err-box {
  background: #1a0d0d;
  color: #ff6961;
  border-radius: 14px;
  padding: 12px 14px;
  font-size: 13px;
  margin-bottom: 14px;
}

.dayrow {
  display: flex;
  gap: 6px;
  margin-bottom: 22px;
}
.daypill {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 10px 0 8px;
  border: 0;
  border-radius: 16px;
  background: transparent;
  color: #f2f2f7;
  cursor: pointer;
  transition: background 0.15s ease;
}
.daypill.sel {
  background: #1b1b1f;
}
.daypill.today .daypill-num {
  color: #fff;
}
.daypill.today:not(.sel) .daypill-num {
  text-decoration: underline;
  text-underline-offset: 3px;
}
.daypill-wd {
  font-size: 11px;
  font-weight: 600;
  color: #8e8e93;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.daypill.sel .daypill-wd {
  color: #d5d5da;
}
.daypill-num {
  font-size: 18px;
  font-weight: 750;
}
.daypill-dots {
  display: flex;
  gap: 3px;
  height: 5px;
  align-items: center;
}
.daypill-dots i {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  display: block;
}

.empty-day {
  padding: 40px 0;
  text-align: center;
  font-size: 14px;
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
}
.tl-end {
  font-size: 13px;
  padding-top: 2px;
  flex-shrink: 0;
}
.tl-row.brk {
  opacity: 0.45;
}
</style>
