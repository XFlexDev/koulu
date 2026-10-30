import React, { useCallback, useEffect, useState } from "react";
import { View, ScrollView, RefreshControl } from "react-native";
import { Text, List, SegmentedButtons, IconButton, Button, ActivityIndicator, Card } from "react-native-paper";
import { SafeAreaView } from "react-native-safe-area-context";
import { api, Week, Day, Lesson } from "../api";

const WD = ["Ma", "Ti", "Ke", "To", "Pe", "La", "Su"];

function mondayOf(d: Date) {
  const m = new Date(d);
  m.setDate(m.getDate() - ((m.getDay() + 6) % 7));
  return m.toISOString().slice(0, 10);
}
const fmt = (iso?: string) => iso?.split("-").reverse().join(".");

export default function WeekScreen() {
  const [anchor, setAnchor] = useState(mondayOf(new Date()));
  const [week, setWeek] = useState<Week | null>(null);
  const [sel, setSel] = useState("0");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const today = new Date().toISOString().slice(0, 10);

  const load = useCallback(() => {
    api
      .schedule(anchor)
      .then((w) => {
        setWeek(w);
        const ti = w.days.findIndex((d: Day) => d.date === today);
        setSel(String(ti >= 0 ? ti : 0));
      })
      .catch((e) => setErr(e.message))
      .finally(() => {
        setLoading(false);
        setRefreshing(false);
      });
  }, [anchor, today]);

  useEffect(load, [load]);

  const shift = (days: number) => {
    const d = new Date(anchor);
    d.setDate(d.getDate() + days);
    setAnchor(d.toISOString().slice(0, 10));
  };

  const weekNum = (() => {
    const s = week?.days[0]?.date;
    if (!s) return null;
    const d = new Date(s);
    const jan1 = new Date(d.getFullYear(), 0, 1);
    return Math.ceil(((d.getTime() - jan1.getTime()) / 86400000 + jan1.getDay() + 1) / 7);
  })();

  const selDay: Day | null = week?.days[Number(sel)] || null;

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: "#000" }} edges={["top"]}>
      <ScrollView
        contentContainerStyle={{ padding: 16, paddingBottom: 40 }}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load(); }} tintColor="#8ab4f8" />
        }
      >
        <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
          <View>
            <Text variant="headlineMedium" style={{ fontWeight: "700" }}>
              Viikko{weekNum ? ` ${weekNum}` : ""}
            </Text>
            <Text variant="bodySmall" style={{ color: "#8e8e93" }}>
              {fmt(week?.week_start)}–{fmt(week?.week_end)}
            </Text>
          </View>
          <View style={{ flexDirection: "row", alignItems: "center" }}>
            <IconButton icon="chevron-left" mode="contained-tonal" size={18} onPress={() => shift(-7)} />
            <Button mode="contained-tonal" compact onPress={() => setAnchor(mondayOf(new Date()))}>
              Nyt
            </Button>
            <IconButton icon="chevron-right" mode="contained-tonal" size={18} onPress={() => shift(7)} />
          </View>
        </View>

        {!!err && <Text style={{ color: "#ff6961", marginBottom: 12 }}>{err}</Text>}
        {loading && <ActivityIndicator style={{ marginVertical: 24 }} />}

        {week && (
          <>
            <SegmentedButtons
              value={sel}
              onValueChange={setSel}
              density="regular"
              buttons={week.days.slice(0, 7).map((d: Day, i: number) => ({
                value: String(i),
                label: `${WD[d.weekday - 1]} ${new Date(d.date).getDate()}`,
                labelStyle: { fontSize: 11 },
              }))}
              style={{ marginBottom: 16 }}
            />

            {selDay && selDay.lessons.length === 0 && (
              <Card mode="elevated" style={{ borderRadius: 20 }}>
                <Card.Content>
                  <Text style={{ color: "#8e8e93", textAlign: "center" }}>Vapaapäivä.</Text>
                </Card.Content>
              </Card>
            )}

            {selDay?.lessons.map((l: Lesson, i: number) => (
              <List.Item
                key={i}
                title={l.subject}
                titleStyle={{ fontWeight: "600" }}
                description={`${l.start}–${l.end}${l.room ? ` · ${l.room}` : ""}${l.teachers.length ? ` · ${l.teachers.join(", ")}` : ""}${l.info ? ` · ${l.info}` : ""}`}
                left={() => (
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
                style={{ opacity: l.break ? 0.4 : 1, paddingVertical: 4 }}
              />
            ))}
          </>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}
