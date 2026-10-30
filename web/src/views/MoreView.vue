<script setup lang="ts">
import { onMounted, ref } from "vue";
import { api } from "../api";

const emit = defineEmits<{ logout: [] }>();
const me = ref<any>(null);
const sec = ref<string | null>(null);

const exams = ref<any[] | null>(null);
const assessments = ref<any[] | null>(null);
const observations = ref<any[] | null>(null);
const excuses = ref<any[] | null>(null);
const news = ref<any[] | null>(null);

const excusePicked = ref<number[]>([]);
const excuseText = ref("");
const excuseBusy = ref(false);
const excuseDone = ref(false);

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
    const a = await api.attendance();
    observations.value = a.observations;
    excuses.value = a.excuses;
  } catch {
    observations.value = [];
    excuses.value = [];
  }
  try {
    news.value = (await api.news()).news;
  } catch {
    news.value = [];
  }
});

async function sendExcuse() {
  excuseBusy.value = true;
  try {
    await api.excuse(excusePicked.value, 3, excuseText.value);
    excuseDone.value = true;
    const a = await api.attendance();
    observations.value = a.observations;
    excuses.value = a.excuses;
    excusePicked.value = [];
  } catch (e: any) {
    alert(e.message);
  } finally {
    excuseBusy.value = false;
  }
}

async function doLogout() {
  try {
    await api.logout();
  } catch {}
  emit("logout");
}
</script>

<template>
  <div class="pt-3 pb-24">
    <div class="d-flex align-center justify-space-between mb-4">
      <div class="text-h5 font-weight-bold">{{ me?.account ? `${me.account.firstname} ${me.account.lastname}` : "Lisää" }}</div>
      <v-btn variant="tonal" size="small" @click="doLogout">Kirjaudu ulos</v-btn>
    </div>

    <v-expansion-panels variant="accordion">
      <v-expansion-panel title="Kokeet" @click="sec === 'exams' || (sec = 'exams')">
        <v-expansion-panel-text>
          <div v-if="!exams" class="text-medium-emphasis">Ladataan…</div>
          <div v-else-if="exams.length === 0" class="text-medium-emphasis">Ei kokeita.</div>
          <div v-for="(e, i) in exams" :key="i" class="py-2 border-b" style="border-color: #1c1c1e">
            <div class="font-weight-medium">{{ e.name || e.subject }}</div>
            <div class="text-caption text-medium-emphasis">{{ e.date }}<template v-if="e.time"> klo {{ e.time }}</template><template v-if="e.course"> · {{ e.course }}</template></div>
            <div v-if="e.info" class="text-caption text-medium-emphasis mt-1">{{ e.info }}</div>
          </div>
        </v-expansion-panel-text>
      </v-expansion-panel>

      <v-expansion-panel title="Arviointikeskustelut">
        <v-expansion-panel-text>
          <div v-if="!assessments" class="text-medium-emphasis">Ladataan…</div>
          <div v-else-if="assessments.length === 0" class="text-medium-emphasis">Ei arviointikeskusteluja.</div>
          <div v-for="(a, i) in assessments" :key="i" class="py-2 border-b" style="border-color: #1c1c1e">
            <div class="font-weight-medium">{{ a.start }} – {{ a.end }}</div>
          </div>
        </v-expansion-panel-text>
      </v-expansion-panel>

      <v-expansion-panel title="Poissaolot">
        <v-expansion-panel-text>
          <div v-if="observations && observations.length" class="mb-4">
            <div class="text-caption text-medium-emphasis mb-2">Merkitse selvitys:</div>
            <v-card
              v-for="o in observations"
              :key="o.id"
              class="pa-3 mb-2 d-flex align-center ga-3"
              :variant="excusePicked.includes(o.id) ? 'outlined' : 'flat'"
              @click="excusePicked = excusePicked.includes(o.id) ? excusePicked.filter((x) => x !== o.id) : [...excusePicked, o.id]"
            >
              <v-checkbox-btn :model-value="excusePicked.includes(o.id)" />
              <div>
                <div class="text-body-2 font-weight-medium">{{ o.timestamp }} — {{ o.type }}</div>
                <div v-if="o.description" class="text-caption text-medium-emphasis">{{ o.description }}</div>
              </div>
            </v-card>
            <v-textarea v-model="excuseText" placeholder="Selvitys (valinnainen)" rows="2" class="mb-2" />
            <v-btn block color="white" class="text-black font-weight-bold" :loading="excuseBusy" :disabled="!excusePicked.length" @click="sendExcuse">
              {{ excuseDone ? "Tallennettu" : "Tallenna selvitys" }}
            </v-btn>
          </div>
          <div v-else-if="observations" class="text-medium-emphasis mb-3">Ei selvittämättömiä poissaoloja.</div>

          <div v-if="excuses && excuses.length">
            <div class="text-caption text-medium-emphasis mb-2">Selvitykset:</div>
            <div v-for="(x, i) in excuses" :key="i" class="py-2 border-b" style="border-color: #1c1c1e">
              <div class="text-body-2 font-weight-medium">{{ x.type }} · {{ x.period }}</div>
              <div class="text-caption text-medium-emphasis">{{ x.description }}</div>
            </div>
          </div>
        </v-expansion-panel-text>
      </v-expansion-panel>

      <v-expansion-panel title="Tiedotteet">
        <v-expansion-panel-text>
          <div v-if="!news" class="text-medium-emphasis">Ladataan…</div>
          <div v-else-if="news.length === 0" class="text-medium-emphasis">Ei tiedotteita.</div>
          <div v-for="(n, i) in news" :key="i" class="py-2 border-b" style="border-color: #1c1c1e">
            <div class="font-weight-medium">{{ n.title }}</div>
            <div class="text-caption text-medium-emphasis">{{ n.publisher }} · {{ n.timestamp }}</div>
            <div class="text-body-2 mt-1">{{ n.description }}</div>
          </div>
        </v-expansion-panel-text>
      </v-expansion-panel>
    </v-expansion-panels>
  </div>
</template>
