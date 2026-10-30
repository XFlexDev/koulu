import AsyncStorage from "@react-native-async-storage/async-storage";

const BASE = "https://koulu.kreatix.dev/api";
const KEY = "koulu:token";

export async function getToken() {
  return AsyncStorage.getItem(KEY);
}
export async function setToken(t: string | null) {
  if (t) await AsyncStorage.setItem(KEY, t);
  else await AsyncStorage.removeItem(KEY);
}

async function req<T = any>(path: string, init?: RequestInit): Promise<T> {
  const t = await getToken();
  const res = await fetch(`${BASE}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(t ? { Authorization: `Bearer ${t}` } : {}),
      ...(init?.headers || {}),
    },
  });
  if (res.status === 401) {
    await setToken(null);
    throw new Error("Session expired — kirjaudu uudelleen");
  }
  if (!res.ok) {
    const j = await res.json().catch(() => null);
    throw new Error(j?.detail || `HTTP ${res.status}`);
  }
  return res.json();
}

export interface Lesson {
  start: string;
  end: string;
  subject: string;
  code: string;
  color: string;
  room: string;
  teachers: string[];
  info?: string;
  break?: boolean;
}
export interface Day {
  date: string;
  weekday: number;
  lessons: Lesson[];
}
export interface Week {
  week_start: string;
  week_end: string;
  days: Day[];
}
export interface Msg {
  id: number;
  subject: string;
  from: string;
  timestamp: string;
  unread: boolean;
  replies: number;
}
export interface Recipient {
  id: number | string;
  name: string;
  type: string;
  n_class?: string | null;
}

export const api = {
  login: (url: string, username: string, password: string) =>
    req<{ token: string }>("/session", { method: "POST", body: JSON.stringify({ url, username, password }) }),
  logout: () => req("/session/logout", { method: "POST" }),
  me: () => req("/me"),
  schedule: (date?: string) => req<Week>(`/schedule${date ? `?date=${date}` : ""}`),
  messages: (folder = "inbox") => req<{ messages: Msg[] }>(`/messages?folder=${folder}`),
  message: (id: number) => req(`/messages/${id}`),
  reply: (id: number, body: string) => req(`/messages/${id}/reply`, { method: "POST", body: JSON.stringify({ body }) }),
  send: (recipients: { id: string; type: string; n_class?: string | null }[], subject: string, body: string) =>
    req("/messages", { method: "POST", body: JSON.stringify({ recipients, subject, body }) }),
  recipients: () => req<{ recipients: Recipient[] }>("/recipients"),
  exams: () => req<{ exams: any[] }>("/exams"),
  news: () => req<{ news: any[] }>("/news"),
  assessments: () => req<{ assessments: any[] }>("/assessments"),
  attendance: () => req<{ observations: any[] }>("/attendance"),
};
