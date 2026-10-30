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
          "surface-bright": "#1c1c1e",
          "surface-variant": "#262628",
          primary: "#ffffff",
          secondary: "#8e8e93",
          "on-surface": "#ffffff",
          "on-background": "#ffffff",
        },
      },
    },
  },
  defaults: {
    VCard: { rounded: "lg", border: true, flat: true, color: "surface" },
    VBtn: { rounded: "lg" },
    VTextField: { variant: "outlined", density: "comfortable", hideDetails: "auto" },
    VTextarea: { variant: "outlined", hideDetails: "auto" },
    VBottomSheet: { inset: false },
  },
});

createApp(App).use(vuetify).mount("#app");
