<script setup lang="ts">
import { ref } from "vue";
import { api, setToken } from "../api";

const emit = defineEmits<{ done: [] }>();
const url = ref("");
const user = ref("");
const pass = ref("");
const err = ref("");
const busy = ref(false);

async function submit() {
  busy.value = true;
  err.value = "";
  try {
    const r = await api.login(url.value.trim(), user.value.trim(), pass.value);
    setToken(r.token);
    emit("done");
  } catch (e: any) {
    err.value = e.message || "Kirjautuminen epäonnistui";
  } finally {
    busy.value = false;
  }
}
</script>

<template>
  <v-container class="d-flex flex-column justify-center fill-height" style="max-width: 400px">
    <div class="text-h3 font-weight-black mb-1" style="letter-spacing: -0.03em">koulu</div>
    <div class="text-body-1 text-medium-emphasis mb-8">Wilma, mutta nopeampi.</div>

    <v-form @submit.prevent="submit">
      <v-text-field v-model="url" label="Wilma-osoite" placeholder="koulu.inschool.fi" autocapitalize="none" class="mb-3" />
      <v-text-field v-model="user" label="Käyttäjätunnus" autocapitalize="none" class="mb-3" />
      <v-text-field v-model="pass" label="Salasana" type="password" class="mb-3" />
      <v-alert v-if="err" type="error" variant="tonal" density="compact" class="mb-3">{{ err }}</v-alert>
      <v-btn type="submit" color="primary" size="x-large" block :loading="busy" :disabled="!url || !user || !pass">
        Kirjaudu
      </v-btn>
    </v-form>

    <div class="text-caption text-disabled mt-8">Sama tunnus kuin Wilmassa.</div>
  </v-container>
</template>
