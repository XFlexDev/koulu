import { createApp } from "vue";
import App from "./App.vue";

import "vuetify/styles";
import "@mdi/font/css/materialdesignicons.css";
import { createVuetify } from "vuetify";

const vuetify = createVuetify({
  theme: {
    defaultTheme: "oled",
    themes: {
      oled: {
        dark: true,
        colors: {
          background: "#000000",
          surface: "#101012",
          "surface-bright": "#1a1a1e",
          "surface-variant": "#26262b",
          primary: "#7cb4ff",
          "primary-darken-1": "#4c9fff",
          secondary: "#9aa0aa",
          "on-surface": "#e8eaf0",
          "on-background": "#e8eaf0",
        },
      },
    },
  },
  defaults: {
    VCard: { rounded: "xl" },
    VBtn: { rounded: "lg" },
    VTextField: { variant: "outlined", density: "comfortable", hideDetails: "auto" },
    VTextarea: { variant: "outlined", hideDetails: "auto" },
    VAutocomplete: { variant: "outlined", density: "comfortable", hideDetails: "auto" },
    VChip: { rounded: "lg" },
  },
});

createApp(App).use(vuetify).mount("#app");
