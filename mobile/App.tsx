import React, { useEffect, useState } from "react";
import { PaperProvider, MD3DarkTheme, BottomNavigation } from "react-native-paper";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { StatusBar } from "react-native";
import { getToken, setToken } from "./src/api";
import LoginScreen from "./src/screens/LoginScreen";
import TodayScreen from "./src/screens/TodayScreen";
import WeekScreen from "./src/screens/WeekScreen";
import MessagesScreen from "./src/screens/MessagesScreen";
import MoreScreen from "./src/screens/MoreScreen";

const theme = {
  ...MD3DarkTheme,
  colors: {
    ...MD3DarkTheme.colors,
    primary: "#8ab4f8",
    secondary: "#9aa0aa",
    background: "#000000",
    surface: "#101013",
    surfaceVariant: "#1b1b20",
    elevation: {
      level0: "transparent",
      level1: "#141418",
      level2: "#1a1a20",
      level3: "#202027",
      level4: "#23232b",
      level5: "#26262f",
    },
  },
};

export default function App() {
  const [authed, setAuthed] = useState<boolean | null>(null);
  const [index, setIndex] = useState(0);

  useEffect(() => {
    getToken().then((t) => setAuthed(!!t));
  }, []);

  const routes = [
    { key: "today", title: "Tänään", focusedIcon: "clock", unfocusedIcon: "clock-outline" },
    { key: "week", title: "Viikko", focusedIcon: "calendar-week" },
    { key: "messages", title: "Viestit", focusedIcon: "message", unfocusedIcon: "message-outline" },
    { key: "more", title: "Lisää", focusedIcon: "dots-horizontal" },
  ];

  const logout = async () => {
    await setToken(null);
    setAuthed(false);
  };

  const renderScene = BottomNavigation.SceneMap({
    today: TodayScreen,
    week: WeekScreen,
    messages: MessagesScreen,
    more: () => <MoreScreen onLogout={logout} />,
  });

  if (authed === null) return null;

  return (
    <PaperProvider theme={theme}>
      <SafeAreaProvider>
        <StatusBar barStyle="light-content" />
        {!authed ? (
          <LoginScreen onDone={() => setAuthed(true)} />
        ) : (
          <BottomNavigation
            navigationState={{ index, routes }}
            onIndexChange={setIndex}
            renderScene={renderScene}
            barStyle={{ backgroundColor: "#101013" }}
            activeColor="#8ab4f8"
            inactiveColor="#77777d"
            theme={theme}
          />
        )}
      </SafeAreaProvider>
    </PaperProvider>
  );
}
