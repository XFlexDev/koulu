import React, { useEffect, useState } from "react";
import { ScrollView, View } from "react-native";
import { Text, List, Card, Button, ActivityIndicator, Chip, Divider } from "react-native-paper";
import { SafeAreaView } from "react-native-safe-area-context";
import { api } from "../api";

export default function MoreScreen({ onLogout }: { onLogout: () => void }) {
  const [me, setMe] = useState<any>(null);
  const [exams, setExams] = useState<any[] | null>(null);
  const [assessments, setAssessments] = useState<any[] | null>(null);
  const [observations, setObservations] = useState<any[] | null>(null);
  const [news, setNews] = useState<any[] | null>(null);

  useEffect(() => {
    api.me().then(setMe).catch(() => {});
    api.exams().then((d) => setExams(d.exams)).catch(() => setExams([]));
    api.assessments().then((d) => setAssessments(d.assessments)).catch(() => setAssessments([]));
    api.attendance().then((d) => setObservations(d.observations)).catch(() => setObservations([]));
    api.news().then((d) => setNews(d.news)).catch(() => setNews([]));
  }, []);

  const logout = async () => {
    try {
      await api.logout();
    } catch {}
    onLogout();
  };

  const Section = ({ label, data, empty, children }: any) => (
    <View style={{ marginBottom: 8 }}>
      <List.Subheader style={{ color: "#8e8e93", textTransform: "uppercase", fontSize: 12, letterSpacing: 1 }}>
        {label}
      </List.Subheader>
      {!data ? (
        <ActivityIndicator style={{ marginVertical: 8 }} />
      ) : data.length === 0 ? (
        <Card mode="elevated" style={{ borderRadius: 16 }}>
          <Card.Content>
            <Text style={{ color: "#8e8e93" }}>{empty}</Text>
          </Card.Content>
        </Card>
      ) : (
        children
      )}
    </View>
  );

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: "#000" }} edges={["top"]}>
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 40 }}>
        <Text variant="headlineMedium" style={{ fontWeight: "700" }}>
          {me?.account ? `${me.account.firstname} ${me.account.lastname}` : "Lisää"}
        </Text>
        <View style={{ height: 12 }} />

        <Section label="Kokeet" data={exams} empty="Ei kokeita.">
          {exams?.map((e, i) => (
            <View key={i}>
              <List.Item
                title={e.name}
                titleStyle={{ fontWeight: "600" }}
                description={`${e.date}${e.time ? ` · ${e.time}` : ""}${e.course || e.course_code ? ` · ${e.course || e.course_code}` : ""}${e.teacher ? ` · ${e.teacher}` : ""}${e.info ? `\n${e.info}` : ""}`}
                descriptionNumberOfLines={8}
              />
              <Divider />
            </View>
          ))}
        </Section>

        <Section label="Arviointikeskustelut" data={assessments} empty="Ei arviointikeskusteluja.">
          {assessments?.map((a, i) => (
            <View key={i}>
              <List.Item title={`${a.start} – ${a.end}`} />
              <Divider />
            </View>
          ))}
        </Section>

        <Section label="Poissaolot" data={observations} empty="Ei selvittämättömiä poissaoloja.">
          {observations?.map((o, i) => (
            <View key={i}>
              <List.Item title={`${o.timestamp} — ${o.type}`} description={o.description} />
              <Divider />
            </View>
          ))}
        </Section>

        <Section label="Tiedotteet" data={news} empty="Ei tiedotteita.">
          {news?.map((x, i) => (
            <View key={i}>
              <List.Item
                title={x.title}
                titleStyle={{ fontWeight: "600" }}
                description={`${x.date}${x.author ? ` · ${x.author}` : ""}${x.description ? `\n${x.description}` : ""}`}
                descriptionNumberOfLines={8}
                right={() => (
                  <View style={{ flexDirection: "row", gap: 4, alignSelf: "center" }}>
                    {!!x.important && <Chip compact>Tärkeä</Chip>}
                    {!!x.sticky && <Chip compact mode="flat">Pysyvä</Chip>}
                  </View>
                )}
              />
              <Divider />
            </View>
          ))}
        </Section>

        <Button mode="contained-tonal" textColor="#ff6961" onPress={logout} style={{ marginTop: 24 }}>
          Kirjaudu ulos
        </Button>
      </ScrollView>
    </SafeAreaView>
  );
}
