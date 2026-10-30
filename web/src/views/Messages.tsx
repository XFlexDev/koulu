import { useEffect, useState } from "react";
import { api } from "../api";

interface Msg {
  id: number;
  subject: string;
  from: string;
  timestamp: string;
  unread: boolean;
  replies: number;
}

export default function Messages() {
  const [folder, setFolder] = useState("inbox");
  const [msgs, setMsgs] = useState<Msg[] | null>(null);
  const [err, setErr] = useState("");
  const [open, setOpen] = useState<number | null>(null);
  const [compose, setCompose] = useState(false);

  useEffect(() => {
    setMsgs(null);
    api
      .messages(folder)
      .then((d) => setMsgs(d.messages))
      .catch((e) => setErr(e.message));
  }, [folder]);

  return (
    <div className="px-4 pt-6 pb-28 fadein">
      <div className="flex items-center justify-between mb-4">
        <div className="text-2xl font-semibold tracking-tight">Viestit</div>
        <button
          onClick={() => setCompose(true)}
          className="card px-4 py-2 text-sm text-neutral-200 active:scale-95 transition"
        >
          Uusi
        </button>
      </div>

      <div className="flex gap-1.5 mb-4">
        {[
          ["inbox", "Saapuneet"],
          ["sent", "Lähetetyt"],
          ["archive", "Arkisto"],
        ].map(([k, label]) => (
          <button
            key={k}
            onClick={() => setFolder(k)}
            className={`flex-1 py-2 rounded-xl text-sm ${
              folder === k ? "bg-white text-black font-semibold" : "bg-[#0a0a0b] text-neutral-400"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {err && <div className="card p-4 text-red-400 text-sm">{err}</div>}
      {!msgs && !err && <div className="text-neutral-500 text-sm">Ladataan…</div>}
      {msgs?.length === 0 && <div className="card p-5 text-neutral-400">Tyhjä.</div>}

      <div className="space-y-2">
        {msgs?.map((m) => (
          <button
            key={m.id}
            onClick={() => setOpen(m.id)}
            className="card w-full px-4 py-3.5 text-left active:scale-[0.99] transition"
          >
            <div className="flex items-start gap-2">
              {m.unread && <div className="w-2 h-2 rounded-full bg-blue-400 mt-1.5 shrink-0" />}
              <div className="flex-1 min-w-0">
                <div className={`truncate ${m.unread ? "font-semibold" : "font-medium"}`}>
                  {m.subject}
                </div>
                <div className="text-xs text-neutral-500 mt-0.5 truncate">
                  {m.from} · {m.timestamp}
                  {m.replies ? ` · ${m.replies} vastausta` : ""}
                </div>
              </div>
            </div>
          </button>
        ))}
      </div>

      {open !== null && <MessageSheet id={open} onClose={() => setOpen(null)} />}
      {compose && <ComposeSheet onClose={() => setCompose(false)} onSent={() => { setCompose(false); setFolder("sent"); }} />}
    </div>
  );
}

function MessageSheet({ id, onClose }: { id: number; onClose: () => void }) {
  const [msg, setMsg] = useState<any>(null);
  const [reply, setReply] = useState("");
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);

  useEffect(() => {
    api.message(id).then(setMsg).catch((e) => setMsg({ error: e.message }));
  }, [id]);

  async function sendReply() {
    setSending(true);
    try {
      await api.reply(id, reply);
      setSent(true);
      setReply("");
    } catch (e: any) {
      alert(e.message);
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-black/60" onClick={onClose}>
      <div
        className="mt-auto bg-[#0c0c0d] border-t border-neutral-800 rounded-t-3xl max-h-[88%] flex flex-col sheet-in"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="w-10 h-1 rounded-full bg-neutral-700 mx-auto mt-3 mb-2" />
        <div className="px-5 pb-4 overflow-y-auto">
          {!msg && <div className="text-neutral-500 text-sm py-4">Ladataan…</div>}
          {msg?.error && <div className="text-red-400 text-sm py-4">{msg.error}</div>}
          {msg && !msg.error && (
            <>
              <div className="text-lg font-semibold leading-snug">{msg.subject}</div>
              <div className="text-xs text-neutral-500 mt-1 mb-4">
                {msg.from} · {msg.timestamp}
              </div>
              <div
                className="text-[15px] leading-relaxed text-neutral-200 [&_p]:mb-3"
                dangerouslySetInnerHTML={{ __html: msg.html || msg.bbcode || "" }}
              />
              {msg.replies?.map((r: any, i: number) => (
                <div key={i} className="card p-4 mt-3">
                  <div className="text-xs text-neutral-500 mb-2">
                    {r.from} · {r.timestamp}
                  </div>
                  <div
                    className="text-sm text-neutral-200 [&_p]:mb-2"
                    dangerouslySetInnerHTML={{ __html: r.html || "" }}
                  />
                </div>
              ))}
              {msg.allow_reply && !sent && (
                <div className="mt-5 flex gap-2">
                  <input
                    className="card flex-1 px-4 py-3 text-sm outline-none focus:border-neutral-600"
                    placeholder="Vastaa…"
                    value={reply}
                    onChange={(e) => setReply(e.target.value)}
                  />
                  <button
                    onClick={sendReply}
                    disabled={sending || !reply.trim()}
                    className="px-5 py-3 rounded-2xl bg-white text-black text-sm font-medium disabled:opacity-40"
                  >
                    →
                  </button>
                </div>
              )}
              {sent && <div className="text-green-400 text-sm mt-4">Vastaus lähetetty.</div>}
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function ComposeSheet({ onClose, onSent }: { onClose: () => void; onSent: () => void }) {
  const [recips, setRecips] = useState<any[] | null>(null);
  const [picked, setPicked] = useState<any[]>([]);
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [busy, setBusy] = useState(false);
  const [q, setQ] = useState("");

  useEffect(() => {
    api.recipients().then((d) => setRecips(d.recipients)).catch(() => setRecips([]));
  }, []);

  const filtered = (recips || []).filter((r) => r.name.toLowerCase().includes(q.toLowerCase()));

  async function send() {
    setBusy(true);
    try {
      await api.send(
        picked.map((p) => ({ id: String(p.id), type: p.type })),
        subject,
        body
      );
      onSent();
    } catch (e: any) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-black/60" onClick={onClose}>
      <div
        className="mt-auto bg-[#0c0c0d] border-t border-neutral-800 rounded-t-3xl max-h-[90%] flex flex-col sheet-in"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="w-10 h-1 rounded-full bg-neutral-700 mx-auto mt-3 mb-2" />
        <div className="px-5 pb-5 overflow-y-auto">
          <div className="text-lg font-semibold mb-4">Uusi viesti</div>
          <input
            className="card w-full px-4 py-3 text-sm outline-none mb-2"
            placeholder="Hae vastaanottajaa…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
          {picked.length > 0 && (
            <div className="flex flex-wrap gap-1.5 mb-2">
              {picked.map((p) => (
                <button
                  key={`${p.type}-${p.id}`}
                  onClick={() => setPicked(picked.filter((x) => x !== p))}
                  className="px-3 py-1.5 rounded-full bg-neutral-800 text-xs"
                >
                  {p.name} ×
                </button>
              ))}
            </div>
          )}
          <div className="max-h-40 overflow-y-auto space-y-1 mb-3">
            {(filtered || []).slice(0, 40).map((r) => (
              <button
                key={`${r.type}-${r.id}`}
                onClick={() => !picked.includes(r) && setPicked([...picked, r])}
                className="card w-full px-3.5 py-2.5 text-left text-sm"
              >
                {r.name}
                <span className="text-xs text-neutral-500 ml-2">{r.type}</span>
              </button>
            ))}
            {recips === null && <div className="text-neutral-500 text-sm">Ladataan…</div>}
          </div>
          <input
            className="card w-full px-4 py-3 text-sm outline-none mb-2"
            placeholder="Aihe"
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
          />
          <textarea
            className="card w-full px-4 py-3 text-sm outline-none min-h-28 mb-3"
            placeholder="Viesti…"
            value={body}
            onChange={(e) => setBody(e.target.value)}
          />
          <button
            onClick={send}
            disabled={busy || !picked.length || !subject.trim() || !body.trim()}
            className="w-full py-3.5 rounded-2xl bg-white text-black font-medium text-sm disabled:opacity-40"
          >
            {busy ? "Lähetetään…" : "Lähetä"}
          </button>
        </div>
      </div>
    </div>
  );
}
