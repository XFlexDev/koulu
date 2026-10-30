import { useState } from "react";
import { getToken, setToken } from "./api";
import Login from "./views/Login";
import Today from "./views/Today";
import Week from "./views/Week";
import Messages from "./views/Messages";
import More from "./views/More";

type Tab = "today" | "week" | "messages" | "more";

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: "today", label: "Tänään", icon: "M12 8v4l2.5 2.5M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" },
  { id: "week", label: "Viikko", icon: "M4 6h16M4 12h16M4 18h16" },
  { id: "messages", label: "Viestit", icon: "M21 11.5a8.5 8.5 0 0 1-8.5 8.5c-1.5 0-3-.4-4.2-1L3 20l1.2-4A8.5 8.5 0 1 1 21 11.5Z" },
  { id: "more", label: "Lisää", icon: "M5 12h.01M12 12h.01M19 12h.01" },
];

export default function App() {
  const [tab, setTab] = useState<Tab>("today");
  const [authed, setAuthed] = useState<boolean>(!!getToken());

  if (!authed) return <Login onDone={() => setAuthed(true)} />;

  return (
    <div className="h-full flex flex-col">
      <div className="flex-1 overflow-y-auto">
        {tab === "today" && <Today />}
        {tab === "week" && <Week />}
        {tab === "messages" && <Messages />}
        {tab === "more" && (
          <More
            onLogout={() => {
              setToken(null);
              setAuthed(false);
            }}
          />
        )}
      </div>
      <nav className="fixed bottom-0 inset-x-0 bg-black/85 backdrop-blur-xl border-t border-neutral-900 pb-[env(safe-area-inset-bottom)]">
        <div className="flex max-w-md mx-auto">
          {TABS.map((t) => (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              className="flex-1 py-2.5 flex flex-col items-center gap-0.5 active:scale-95 transition"
            >
              <svg
                width="22"
                height="22"
                viewBox="0 0 24 24"
                fill="none"
                stroke={tab === t.id ? "#fff" : "#555"}
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d={t.icon} />
              </svg>
              <span className={`text-[10px] ${tab === t.id ? "text-white" : "text-neutral-600"}`}>
                {t.label}
              </span>
            </button>
          ))}
        </div>
      </nav>
    </div>
  );
}
