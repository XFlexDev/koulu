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
    <div class="mt-4 mb-5">
      <div class="text-h5 font-weight-bold">{{ me?.account ? `${me.account.firstname} ${me.account.lastname}` : "Lisää" }}</div>
      <div v-if="me?.school" class="text-caption text-medium-emphasis">{{ me.school }}</div>
    </div>

    <v-list-subheader class="px-0 text-uppercase">Kokeet</v-list-subheader>
    <v-progress-linear v-if="!exams" indeterminate color="primary" class="mb-2" />
    <v-card v-else-if="exams.length === 0" variant="tonal" class="mb-2">
      <v-card-text class="text-medium-emphasis py-4">Ei kokeita.</v-card-text>
    </v-card>
    <v-list v-else bg-color="transparent" lines="three" class="pa-0 mb-2">
      <v-list-item v-for="(e, i) in exams" :key="i" class="px-0">
        <v-list-item-title class="font-weight-medium">{{ e.name }}</v-list-item-title>
        <v-list-item-subtitle>
          {{ e.date }}<template v-if="e.time"> · {{ e.time }}</template>
          <template v-if="e.course || e.course_code"> · {{ e.course || e.course_code }}</template>
          <template v-if="e.teacher"> · {{ e.teacher }}</template>
        </v-list-item-subtitle>
        <v-list-item-subtitle v-if="e.info" style="-webkit-line-clamp: unset">{{ e.info }}</v-list-item-subtitle>
      </v-list-item>
    </v-list>

    <v-list-subheader class="px-0 text-uppercase">Arviointikeskustelut</v-list-subheader>
    <v-progress-linear v-if="!assessments" indeterminate color="primary" class="mb-2" />
    <v-card v-else-if="assessments.length === 0" variant="tonal" class="mb-2">
      <v-card-text class="text-medium-emphasis py-4">Ei arviointikeskusteluja.</v-card-text>
    </v-card>
    <v-list v-else bg-color="transparent" class="pa-0 mb-2">
      <v-list-item v-for="(a, i) in assessments" :key="i" class="px-0">
        <v-list-item-title>{{ a.start }} – {{ a.end }}</v-list-item-title>
      </v-list-item>
    </v-list>

    <v-list-subheader class="px-0 text-uppercase">Poissaolot</v-list-subheader>
    <v-progress-linear v-if="!observations" indeterminate color="primary" class="mb-2" />
    <v-card v-else-if="observations.length === 0" variant="tonal" class="mb-2">
      <v-card-text class="text-medium-emphasis py-4">Ei selvittämättömiä poissaoloja.</v-card-text>
    </v-card>
    <v-list v-else bg-color="transparent" lines="two" class="pa-0 mb-2">
      <v-list-item v-for="(o, i) in observations" :key="i" class="px-0">
        <v-list-item-title>{{ o.timestamp }} — {{ o.type }}</v-list-item-title>
        <v-list-item-subtitle v-if="o.description">{{ o.description }}</v-list-item-subtitle>
      </v-list-item>
    </v-list>

    <v-list-subheader class="px-0 text-uppercase">Tiedotteet</v-list-subheader>
    <v-progress-linear v-if="!news" indeterminate color="primary" class="mb-2" />
    <v-card v-else-if="news.length === 0" variant="tonal" class="mb-2">
      <v-card-text class="text-medium-emphasis py-4">Ei tiedotteita.</v-card-text>
    </v-card>
    <v-list v-else bg-color="transparent" lines="three" class="pa-0 mb-2">
      <v-list-item v-for="(x, i) in news" :key="i" class="px-0">
        <v-list-item-title class="font-weight-medium">
          {{ x.title }}
          <v-chip v-if="x.important" size="x-small" color="primary" class="ml-2">Tärkeä</v-chip>
          <v-chip v-if="x.sticky" size="x-small" variant="tonal" class="ml-1">Pysyvä</v-chip>
        </v-list-item-title>
        <v-list-item-subtitle>{{ x.date }}<template v-if="x.author"> · {{ x.author }}</template></v-list-item-subtitle>
        <v-list-item-subtitle v-if="x.description" style="-webkit-line-clamp: unset">{{ x.description }}</v-list-item-subtitle>
      </v-list-item>
    </v-list>

    <v-btn color="error" variant="tonal" block size="large" class="mt-8" @click="doLogout">Kirjaudu ulos</v-btn>
  </div>
</template>
