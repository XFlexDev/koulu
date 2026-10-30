import React, { useCallback, useState } from "react";
import { View, ScrollView, RefreshControl } from "react-native";
import { Text, Card, List, ProgressBar, ActivityIndicator } from "react-native-paper";
import { SafeAreaView } from "react-native-safe-area-context";
import { api, Week, Day, Lesson } from "../api";

const toMin = (t?: string) => {
  if (!t) return -1;
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
};
const nowMin = () => {
  const n = new Date();
  return n.getHours() * 60 + n.getMinutes();
};

export default function TodayScreen() {
  const [week, setWeek] = useState<Week | null>(null);
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const todayStr = new Date().toISOString().slice(0, 10);

  const load = useCallback(() => {
    api
      .schedule(todayStr)
      .then((w) => setWeek(w))
      .catch((e) => setErr(e.message))
      .finally(() => {
        setLoading(false);
        setRefreshing(false);
      });
  }, [todayStr]);

  React.useEffect(load, [load]);

  const day: Day | null = week?.days.find((d) => d.date === todayStr) || null;
  const n = nowMin();
  const lessons = day?.lessons || [];
  const teach = lessons.filter((l) => !l.break);
  const current = lessons.find((l) => !l.break && toMin(l.start) <= n && toMin(l.end) > n);
  const next = lessons.find((l) => !l.break && toMin(l.start) > n);
  const done = teach.length > 0 && !current && !next;

  const dateLabel = new Date().toLocaleDateString("fi-FI", {
    weekday: "long",
    day: "numeric",
    month: "long",
  });

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: "#000" }} edges={["top"]}>
      <ScrollView
        contentContainerStyle={{ padding: 16, paddingBottom: 40 }}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load(); }} tintColor="#8ab4f8" />
        }
      >
        <Text variant="headlineMedium" style={{ fontWeight: "700", marginBottom: 16 }}>
          {dateLabel.charAt(0).toUpperCase() + dateLabel.slice(1)}
        </Text>

        {!!err && <Text style={{ color: "#ff6961", marginBottom: 12 }}>{err}</Text>}
        {loading && <ActivityIndicator style={{ marginVertical: 24 }} />}

        {day && current && (
          <Card mode="elevated" style={{ marginBottom: 16, borderRadius: 20 }}>
            <Card.Title title="Nyt" titleStyle={{ fontSize: 13, color: "#9aa0aa" }} subtitle={undefined} />
            <Card.Content style={{ paddingTop: 0 }}>
              <Text variant="titleLarge" style={{ fontWeight: "700" }}>
                {current.subject}
              </Text>
              <Text variant="bodyMedium" style={{ color: "#b8b8bf", marginTop: 4 }}>
                {current.start}–{current.end}
                {current.room ? ` · ${current.room}` : ""}
                {current.teachers[0] ? ` · ${current.teachers[0]}` : ""}
              </Text>
              <ProgressBar
                progress={Math.min(1, Math.max(0, (n - toMin(current.start)) / (toMin(current.end) - toMin(current.start))))}
                color={current.color}
                style={{ marginTop: 14, height: 4, borderRadius: 99 }}
              />
              <Text variant="bodySmall" style={{ color: "#8e8e93", marginTop: 8 }}>
                {toMin(current.end) - n} min jäljellä
              </Text>
            </Card.Content>
          </Card>
        )}

        {day && !current && next && !done && (
          <Card mode="elevated" style={{ marginBottom: 16, borderRadius: 20 }}>
            <Card.Title title="Seuraavaksi" titleStyle={{ fontSize: 13, color: "#9aa0aa" }} />
            <Card.Content style={{ paddingTop: 0 }}>
              <Text variant="titleLarge" style={{ fontWeight: "700" }}>
                {next.subject}
              </Text>
              <Text variant="bodyMedium" style={{ color: "#b8b8bf", marginTop: 4 }}>
                klo {next.start}
                {next.room ? ` · ${next.room}` : ""} · {toMin(next.start) - n} min päästä
              </Text>
            </Card.Content>
          </Card>
        )}

        {day && done && (
          <Card mode="elevated" style={{ marginBottom: 16, borderRadius: 20 }}>
            <Card.Content>
              <Text variant="titleMedium" style={{ fontWeight: "700" }}>
                Päivä ohi
              </Text>
            </Card.Content>
          </Card>
        )}
        {day && lessons.length === 0 && (
          <Card mode="elevated" style={{ marginBottom: 16, borderRadius: 20 }}>
            <Card.Content>
              <Text variant="titleMedium" style={{ fontWeight: "700" }}>
                Ei tunteja tänään
              </Text>
            </Card.Content>
          </Card>
        )}

        {lessons.map((l: Lesson, i: number) => (
          <List.Item
            key={i}
            title={l.subject}
            titleStyle={{ fontWeight: "600" }}
            description={`${l.start}–${l.end}${l.room ? ` · ${l.room}` : ""}${l.teachers.length ? ` · ${l.teachers.join(", ")}` : ""}`}
            left={(p) => (
              <View
                style={{
                  width: 9,
                  height: 9,
                  borderRadius: 99,
                  backgroundColor: l.break ? "#333" : l.color,
                  marginLeft: 12,
                  marginTop: 8,
                }}
              />
            )}
            style={{ opacity: toMin(l.end) <= n || l.break ? 0.4 : 1, paddingVertical: 4 }}
          />
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}
