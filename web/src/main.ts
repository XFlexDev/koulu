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
          surface: "#0c0c0e",
          "surface-bright": "#161618",
          "surface-variant": "#1c1c20",
          primary: "#ffffff",
          secondary: "#8e8e93",
          "on-surface": "#f2f2f7",
          "on-background": "#f2f2f7",
        },
      },
    },
  },
  defaults: {
    VCard: { rounded: "xl", flat: true, color: "surface" },
    VBtn: { rounded: "lg" },
    VTextField: { variant: "solo-filled", density: "comfortable", hideDetails: "auto", rounded: "lg", flat: true },
    VTextarea: { variant: "solo-filled", hideDetails: "auto", rounded: "lg", flat: true },
    VBottomSheet: { inset: false },
    VAlert: { rounded: "lg", density: "comfortable" },
    VChip: { rounded: "lg" },
  },
});

createApp(App).use(vuetify).mount("#app");
