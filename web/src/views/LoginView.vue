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
  <v-container class="fill-height" style="max-width: 420px">
    <div class="w-100">
      <div class="text-h4 font-weight-bold mb-1">koulu</div>
      <div class="text-body-2 text-medium-emphasis mb-8">Wilma, mutta nopeampi.</div>
      <v-form @submit.prevent="submit">
        <v-text-field v-model="url" label="Wilma-osoite" placeholder="koulu.inschool.fi" class="mb-3" autocapitalize="none" />
        <v-text-field v-model="user" label="Käyttäjätunnus" class="mb-3" autocapitalize="none" />
        <v-text-field v-model="pass" label="Salasana" type="password" class="mb-3" />
        <v-alert v-if="err" type="error" variant="tonal" density="compact" class="mb-3">{{ err }}</v-alert>
        <v-btn
          type="submit"
          block
          size="large"
          color="white"
          class="text-black font-weight-bold"
          :loading="busy"
          :disabled="!url || !user || !pass"
        >
          Kirjaudu
        </v-btn>
      </v-form>
      <div class="text-caption text-medium-emphasis mt-6">
        Sama tunnus kuin Wilmassa. Sessio pysyy elossa palvelimella — salasanaa ei tallenneta laitteelle.
      </div>
    </div>
  </v-container>
</template>
