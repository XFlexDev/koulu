<script setup lang="ts">
import { onMounted, ref } from "vue";
import { api } from "../api";

const emit = defineEmits<{ logout: [] }>();
const me = ref<any>(null);

const exams = ref<any[] | null>(null);
const assessments = ref<any[] | null>(null);
const observations = ref<any[] | null>(null);
const news = ref<any[] | null>(null);

onMounted(async () => {
  try {
    me.value = await api.me();
  } catch {}
  try {
    exams.value = (await api.exams()).exams;
  } catch {
    exams.value = [];
  }
  try {
    assessments.value = (await api.assessments()).assessments;
  } catch {
    assessments.value = [];
  }
  try {
    observations.value = (await api.attendance()).observations;
  } catch {
    observations.value = [];
  }
  try {
    news.value = (await api.news()).news;
  } catch {
    news.value = [];
  }
});

async function doLogout() {
  try {
    await api.logout();
  } catch {}
  emit("logout");
}
</script>

<template>
  <div>
    <div class="more-head">
      <div class="big-title">{{ me?.account?.firstname || "Lisää" }}</div>
      <div class="subtle" style="font-size: 13px; margin-top: 2px">
        {{ me?.account ? `${me.account.firstname} ${me.account.lastname}` : "" }}
      </div>
    </div>

    <div class="sec-label">Kokeet</div>
    <div v-if="!exams" class="subtle sec-pad">Ladataan…</div>
    <div v-else-if="exams.length === 0" class="subtle sec-pad">Ei kokeita.</div>
    <div v-else class="ilist">
      <div v-for="(e, i) in exams" :key="i" class="irow">
        <div class="irow-date mono-time">{{ e.date }}<span v-if="e.time"> · {{ e.time }}</span></div>
        <div class="irow-main">
          <div class="irow-title">{{ e.name }}</div>
          <div class="irow-sub subtle">
            {{ e.course || e.course_code }}<template v-if="e.teacher"> · {{ e.teacher }}</template>
          </div>
          <div v-if="e.info" class="irow-info subtle">{{ e.info }}</div>
        </div>
      </div>
    </div>

    <div class="sec-label">Arviointikeskustelut</div>
    <div v-if="!assessments" class="subtle sec-pad">Ladataan…</div>
    <div v-else-if="assessments.length === 0" class="subtle sec-pad">Ei arviointikeskusteluja.</div>
    <div v-else class="ilist">
      <div v-for="(a, i) in assessments" :key="i" class="irow">
        <div class="irow-main">
          <div class="irow-title mono-time">{{ a.start }} – {{ a.end }}</div>
        </div>
      </div>
    </div>

    <div class="sec-label">Poissaolot</div>
    <div v-if="!observations" class="subtle sec-pad">Ladataan…</div>
    <div v-else-if="observations.length === 0" class="subtle sec-pad">Ei selvittämättömiä poissaoloja.</div>
    <div v-else class="ilist">
      <div v-for="(o, i) in observations" :key="i" class="irow">
        <div class="irow-main">
          <div class="irow-title">{{ o.timestamp }} — {{ o.type }}</div>
          <div v-if="o.description" class="irow-sub subtle">{{ o.description }}</div>
        </div>
      </div>
    </div>

    <div class="sec-label">Tiedotteet</div>
    <div v-if="!news" class="subtle sec-pad">Ladataan…</div>
    <div v-else-if="news.length === 0" class="subtle sec-pad">Ei tiedotteita.</div>
    <div v-else class="ilist">
      <div v-for="(x, i) in news" :key="i" class="irow">
        <div class="irow-main">
          <div class="irow-title">
            {{ x.title }}
            <span v-if="x.important" class="tag">Tärkeä</span>
            <span v-if="x.sticky" class="tag">Pysyvä</span>
          </div>
          <div class="irow-sub subtle">{{ x.date }}<template v-if="x.author"> · {{ x.author }}</template></div>
          <div v-if="x.description" class="irow-info subtle">{{ x.description }}</div>
        </div>
      </div>
    </div>

    <button class="logout" @click="doLogout">Kirjaudu ulos</button>
  </div>
</template>

<style scoped>
.more-head {
  margin: 14px 0 26px;
}
.sec-label {
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #8e8e93;
  margin: 26px 0 8px;
}
.sec-pad {
  padding: 8px 2px 4px;
  font-size: 14px;
}
.ilist {
  display: flex;
  flex-direction: column;
}
.irow {
  display: flex;
  gap: 12px;
  padding: 12px 2px;
  border-bottom: 1px solid #141416;
}
.irow:last-child {
  border-bottom: 0;
}
.irow-date {
  font-size: 13px;
  color: #b8b8bf;
  width: 108px;
  flex-shrink: 0;
  padding-top: 2px;
}
.irow-main {
  flex: 1;
  min-width: 0;
}
.irow-title {
  font-size: 15px;
  font-weight: 600;
}
.irow-sub {
  font-size: 12.5px;
  margin-top: 2px;
}
.irow-info {
  font-size: 12.5px;
  margin-top: 4px;
  line-height: 1.45;
}
.tag {
  display: inline-block;
  font-size: 10.5px;
  font-weight: 700;
  background: #26262b;
  color: #d5d5da;
  border-radius: 6px;
  padding: 2px 6px;
  margin-left: 6px;
  vertical-align: 2px;
}
.logout {
  margin-top: 36px;
  width: 100%;
  height: 48px;
  border: 0;
  border-radius: 14px;
  background: #161618;
  color: #ff6961;
  font-size: 14px;
  font-weight: 650;
  cursor: pointer;
}
.logout:active {
  transform: scale(0.99);
}
</style>
