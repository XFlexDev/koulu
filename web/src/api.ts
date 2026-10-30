const TOKEN_KEY = "koulu:token";

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}
export function setToken(t: string | null) {
  if (t) localStorage.setItem(TOKEN_KEY, t);
  else localStorage.removeItem(TOKEN_KEY);
}

async function req(path: string, opts: RequestInit = {}): Promise<any> {
  const t = getToken();
  const r = await fetch(`/api${path}`, {
    ...opts,
    headers: {
      "Content-Type": "application/json",
      ...(t ? { Authorization: `Bearer ${t}` } : {}),
      ...(opts.headers || {}),
    },
  });
  if (r.status === 401) {
    setToken(null);
    location.reload();
    throw new Error("session expired");
  }
  const data = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(data.detail || `HTTP ${r.status}`);
  return data;
}

export const api = {
  login: (url: string, username: string, password: string) =>
    req("/session", { method: "POST", body: JSON.stringify({ url, username, password }) }),
  logout: () => req("/session/logout", { method: "POST" }),
  me: () => req("/me"),
  schedule: (date?: string) => req(`/schedule${date ? `?date=${date}` : ""}`),
  messages: (folder = "inbox") => req(`/messages?folder=${folder}`),
  message: (id: number) => req(`/messages/${id}`),
  reply: (id: number, body: string) =>
    req(`/messages/${id}/reply`, { method: "POST", body: JSON.stringify({ body }) }),
  send: (recipients: { id: string; type: string }[], subject: string, body: string) =>
    req("/messages", { method: "POST", body: JSON.stringify({ recipients, subject, body }) }),
  recipients: () => req("/recipients"),
  exams: () => req("/exams"),
  news: () => req("/news"),
  assessments: () => req("/assessments"),
  attendance: () => req("/attendance"),
  excuse: (ids: number[], type: number, text = "") =>
    req("/attendance/excuse", { method: "POST", body: JSON.stringify({ ids, type, text }) }),
};

export interface Lesson {
  start: string;
  end: string;
  subject: string;
  code: string;
  color: string;
  room: string;
  class?: string;
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
  days: Day[];
}
