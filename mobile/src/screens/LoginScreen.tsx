import React, { useState } from "react";
import { View, KeyboardAvoidingView, Platform, ScrollView } from "react-native";
import { Text, TextInput, Button, HelperText } from "react-native-paper";
import { SafeAreaView } from "react-native-safe-area-context";
import { api, setToken } from "../api";

export default function LoginScreen({ onDone }: { onDone: () => void }) {
  const [url, setUrl] = useState("");
  const [user, setUser] = useState("");
  const [pass, setPass] = useState("");
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setBusy(true);
    setErr("");
    try {
      const r = await api.login(url.trim(), user.trim(), pass);
      await setToken(r.token);
      onDone();
    } catch (e: any) {
      setErr(e.message || "Kirjautuminen epäonnistui");
    } finally {
      setBusy(false);
    }
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: "#000" }}>
      <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} style={{ flex: 1 }}>
        <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: "center", padding: 28 }}>
          <Text variant="displaySmall" style={{ fontWeight: "800" }}>
            koulu
          </Text>
          <Text variant="bodyLarge" style={{ color: "#9aa0aa", marginTop: 4, marginBottom: 36 }}>
            Wilma, mutta nopeampi.
          </Text>

          <TextInput
            label="Wilma-osoite"
            placeholder="koulu.inschool.fi"
            value={url}
            onChangeText={setUrl}
            mode="outlined"
            autoCapitalize="none"
            autoCorrect={false}
            keyboardType="url"
            style={{ marginBottom: 12 }}
          />
          <TextInput
            label="Käyttäjätunnus"
            value={user}
            onChangeText={setUser}
            mode="outlined"
            autoCapitalize="none"
            autoCorrect={false}
            style={{ marginBottom: 12 }}
          />
          <TextInput
            label="Salasana"
            value={pass}
            onChangeText={setPass}
            mode="outlined"
            secureTextEntry
            style={{ marginBottom: 12 }}
          />
          {!!err && (
            <HelperText type="error" visible>
              {err}
            </HelperText>
          )}
          <Button
            mode="contained"
            onPress={submit}
            loading={busy}
            disabled={busy || !url || !user || !pass}
            contentStyle={{ paddingVertical: 8 }}
            style={{ borderRadius: 14, marginTop: 8 }}
          >
            Kirjaudu
          </Button>
          <Text variant="bodySmall" style={{ color: "#66666d", marginTop: 32 }}>
            Sama tunnus kuin Wilmassa.
          </Text>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
