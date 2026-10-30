import React, { useCallback, useEffect, useState } from "react";
import { ScrollView, View, RefreshControl } from "react-native";
import {
  Text,
  List,
  SegmentedButtons,
  ActivityIndicator,
  Card,
  FAB,
  Modal,
  Portal,
  TextInput,
  Button,
  Chip,
  Divider,
} from "react-native-paper";
import { SafeAreaView } from "react-native-safe-area-context";
import { api, Msg, Recipient } from "../api";

export default function MessagesScreen() {
  const [folder, setFolder] = useState("inbox");
  const [msgs, setMsgs] = useState<Msg[] | null>(null);
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const [open, setOpen] = useState<Msg | null>(null);
  const [msg, setMsg] = useState<any>(null);
  const [reply, setReply] = useState("");
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);

  const [compose, setCompose] = useState(false);
  const [recips, setRecips] = useState<Recipient[]>([]);
  const [picked, setPicked] = useState<Recipient[]>([]);
  const [rq, setRq] = useState("");
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");

  const load = useCallback(() => {
    api
      .messages(folder)
      .then((d) => setMsgs(d.messages))
      .catch((e) => setErr(e.message))
      .finally(() => {
        setLoading(false);
        setRefreshing(false);
      });
  }, [folder]);

  useEffect(load, [load]);

  const openMsg = async (m: Msg) => {
    setOpen(m);
    setMsg(null);
    setReply("");
    setSent(false);
    try {
      setMsg(await api.message(m.id));
    } catch (e: any) {
      setMsg({ error: e.message });
    }
  };

  const sendReply = async () => {
    if (!open) return;
    setSending(true);
    try {
      await api.reply(open.id, reply);
      setSent(true);
      setReply("");
    } catch (e: any) {
      setMsg({ ...msg, error: e.message });
    } finally {
      setSending(false);
    }
  };

  const openCompose = async () => {
    setCompose(true);
    if (!recips.length) {
      try {
        setRecips((await api.recipients()).recipients);
      } catch {}
    }
  };

  const send = async () => {
    setSending(true);
    try {
      await api.send(
        picked.map((p) => ({ id: String(p.id), type: p.type, n_class: p.n_class })),
        subject,
        body
      );
      setCompose(false);
      setPicked([]);
      setSubject("");
      setBody("");
      setFolder("sent");
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setSending(false);
    }
  };

  const filteredRecips = recips.filter((r) => r.name.toLowerCase().includes(rq.toLowerCase())).slice(0, 30);

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: "#000" }} edges={["top"]}>
      <View style={{ padding: 16, paddingBottom: 0, flex: 1 }}>
        <Text variant="headlineMedium" style={{ fontWeight: "700", marginBottom: 12 }}>
          Viestit
        </Text>
        <SegmentedButtons
          value={folder}
          onValueChange={setFolder}
          buttons={[
            { value: "inbox", label: "Saapuneet" },
            { value: "sent", label: "Lähetetyt" },
            { value: "archive", label: "Arkisto" },
          ]}
          style={{ marginBottom: 12 }}
        />
        {!!err && <Text style={{ color: "#ff6961", marginBottom: 8 }}>{err}</Text>}
        {loading && <ActivityIndicator style={{ marginVertical: 24 }} />}

        <ScrollView
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={() => {
                setRefreshing(true);
                load();
              }}
              tintColor="#8ab4f8"
            />
          }
        >
          {msgs?.length === 0 && (
            <Card mode="elevated" style={{ borderRadius: 20 }}>
              <Card.Content>
                <Text style={{ color: "#8e8e93", textAlign: "center" }}>Tyhjä.</Text>
              </Card.Content>
            </Card>
          )}
          {msgs?.map((m) => (
            <View key={m.id}>
              <List.Item
                title={m.subject}
                titleStyle={{ fontWeight: m.unread ? "800" : "600" }}
                description={`${m.from}${m.replies ? ` · ${m.replies} vastausta` : ""}`}
                right={() => (
                  <Text variant="bodySmall" style={{ color: "#8e8e93", alignSelf: "center" }}>
                    {(m.timestamp || "").slice(5, 10).replace("-", ".")}
                  </Text>
                )}
                left={() =>
                  m.unread ? (
                    <View
                      style={{
                        width: 8,
                        height: 8,
                        borderRadius: 99,
                        backgroundColor: "#8ab4f8",
                        alignSelf: "center",
                        marginLeft: 8,
                      }}
                    />
                  ) : null
                }
                onPress={() => openMsg(m)}
              />
              <Divider />
            </View>
          ))}
          <View style={{ height: 80 }} />
        </ScrollView>
      </View>

      <FAB icon="pencil" onPress={openCompose} style={{ position: "absolute", right: 20, bottom: 24 }} />

      <Portal>
        <Modal
          visible={!!open}
          onDismiss={() => setOpen(null)}
          contentContainerStyle={{
            backgroundColor: "#101013",
            margin: 20,
            borderRadius: 24,
            padding: 20,
            maxHeight: "85%",
          }}
        >
          {!msg ? (
            <ActivityIndicator />
          ) : msg.error ? (
            <Text style={{ color: "#ff6961" }}>{msg.error}</Text>
          ) : (
            <ScrollView>
              <Text variant="titleLarge" style={{ fontWeight: "700" }}>
                {msg.subject}
              </Text>
              <Text variant="bodySmall" style={{ color: "#8e8e93", marginTop: 4, marginBottom: 12 }}>
                {msg.from} · {msg.timestamp}
              </Text>
              <Text variant="bodyMedium" style={{ lineHeight: 22 }}>
                {(msg.text || msg.html || "").replace(/<[^>]+>/g, "").replace(/&nbsp;/g, " ").trim()}
              </Text>
              {(msg.replies || []).map((r: any, i: number) => (
                <Card key={i} mode="contained" style={{ marginTop: 12, borderRadius: 16 }}>
                  <Card.Content>
                    <Text variant="bodySmall" style={{ color: "#8e8e93", marginBottom: 6 }}>
                      {r.from} · {r.timestamp}
                    </Text>
                    <Text variant="bodyMedium">{(r.text || r.html || "").replace(/<[^>]+>/g, "").trim()}</Text>
                  </Card.Content>
                </Card>
              ))}
              {msg.allow_reply && !sent && (
                <View style={{ flexDirection: "row", alignItems: "center", marginTop: 16, gap: 8 }}>
                  <TextInput
                    value={reply}
                    onChangeText={setReply}
                    placeholder="Vastaa…"
                    mode="outlined"
                    dense
                    style={{ flex: 1 }}
                  />
                  <Button mode="contained" onPress={sendReply} loading={sending} disabled={!reply.trim()}>
                    Lähetä
                  </Button>
                </View>
              )}
              {sent && (
                <Text style={{ color: "#4ade80", marginTop: 14 }}>Vastaus lähetetty.</Text>
              )}
            </ScrollView>
          )}
        </Modal>

        <Modal
          visible={compose}
          onDismiss={() => setCompose(false)}
          contentContainerStyle={{
            backgroundColor: "#101013",
            margin: 20,
            borderRadius: 24,
            padding: 20,
            maxHeight: "90%",
          }}
        >
          <ScrollView>
            <Text variant="titleLarge" style={{ fontWeight: "700", marginBottom: 14 }}>
              Uusi viesti
            </Text>
            <TextInput label="Hae vastaanottajaa" value={rq} onChangeText={setRq} mode="outlined" dense style={{ marginBottom: 8 }} />
            {picked.length > 0 && (
              <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6, marginBottom: 8 }}>
                {picked.map((p) => (
                  <Chip key={`${p.type}-${p.id}`} onClose={() => setPicked(picked.filter((x) => x !== p))}>
                    {p.name}
                  </Chip>
                ))}
              </View>
            )}
            <View style={{ maxHeight: 170, borderRadius: 12, backgroundColor: "#0a0a0c", marginBottom: 10 }}>
              <ScrollView nestedScrollEnabled>
                {filteredRecips.map((r) => (
                  <List.Item
                    key={`${r.type}-${r.id}-${r.n_class || ""}`}
                    title={r.name}
                    description={r.type}
                    onPress={() => !picked.includes(r) && setPicked([...picked, r])}
                    style={{ paddingVertical: 4 }}
                  />
                ))}
              </ScrollView>
            </View>
            <TextInput label="Aihe" value={subject} onChangeText={setSubject} mode="outlined" style={{ marginBottom: 10 }} />
            <TextInput label="Viesti" value={body} onChangeText={setBody} mode="outlined" multiline numberOfLines={4} style={{ marginBottom: 10 }} />
            <Button
              mode="contained"
              onPress={send}
              loading={sending}
              disabled={!picked.length || !subject.trim() || !body.trim()}
              contentStyle={{ paddingVertical: 6 }}
            >
              Lähetä
            </Button>
          </ScrollView>
        </Modal>
      </Portal>
    </SafeAreaView>
  );
}
