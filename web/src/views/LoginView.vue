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
  <div class="login-wrap">
    <div class="login-inner">
      <div class="brand">koulu</div>
      <div class="brand-sub">Wilma, mutta nopeampi.</div>

      <form class="login-form" @submit.prevent="submit">
        <input v-model="url" class="field" placeholder="koulu.inschool.fi" autocapitalize="none" spellcheck="false" />
        <input v-model="user" class="field" placeholder="Käyttäjätunnus" autocapitalize="none" spellcheck="false" />
        <input v-model="pass" class="field" type="password" placeholder="Salasana" />
        <div v-if="err" class="login-err">{{ err }}</div>
        <button class="login-btn" type="submit" :disabled="busy || !url || !user || !pass">
          {{ busy ? "Kirjaudutaan…" : "Kirjaudu" }}
        </button>
      </form>

      <div class="login-foot">Sama tunnus kuin Wilmassa.</div>
    </div>
  </div>
</template>

<style scoped>
.login-wrap {
  min-height: 100dvh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}
.login-inner {
  width: 100%;
  max-width: 340px;
}
.brand {
  font-size: 52px;
  font-weight: 800;
  letter-spacing: -0.03em;
  line-height: 1;
}
.brand-sub {
  color: #8e8e93;
  font-size: 15px;
  margin: 6px 0 40px;
}
.login-form {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.field {
  width: 100%;
  height: 50px;
  padding: 0 16px;
  border: 0;
  border-radius: 14px;
  background: #141416;
  color: #f2f2f7;
  font-size: 15px;
  outline: none;
  transition: background 0.15s ease;
}
.field::placeholder {
  color: #63636b;
}
.field:focus {
  background: #1d1d21;
}
.login-err {
  color: #ff6961;
  font-size: 13px;
  padding: 2px 4px;
}
.login-btn {
  height: 50px;
  margin-top: 6px;
  border: 0;
  border-radius: 14px;
  background: #fff;
  color: #000;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: opacity 0.15s ease, transform 0.1s ease;
}
.login-btn:active {
  transform: scale(0.985);
}
.login-btn:disabled {
  opacity: 0.35;
}
.login-foot {
  margin-top: 48px;
  color: #56565e;
  font-size: 12.5px;
}
</style>
