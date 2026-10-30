import { useState } from "react";
import { api, setToken } from "../api";

export default function Login({ onDone }: { onDone: () => void }) {
  const [url, setUrl] = useState("");
  const [user, setUser] = useState("");
  const [pass, setPass] = useState("");
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setErr("");
    try {
      const r = await api.login(url.trim(), user.trim(), pass);
      setToken(r.token);
      onDone();
    } catch (e: any) {
      setErr(e.message || "Kirjautuminen epäonnistui");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="min-h-full flex flex-col items-center justify-center px-6 fadein">
      <div className="w-full max-w-sm">
        <div className="mb-10">
          <div className="text-3xl font-semibold tracking-tight">koulu</div>
          <div className="text-neutral-500 text-sm mt-1">Wilma, mutta nopeampi.</div>
        </div>
        <form onSubmit={submit} className="space-y-3">
          <input
            className="card w-full px-4 py-3.5 text-[15px] outline-none focus:border-neutral-600 placeholder:text-neutral-600"
            placeholder="Wilma-osoite (esim. koulu.inschool.fi)"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            autoCapitalize="none"
            autoCorrect="off"
            inputMode="url"
          />
          <input
            className="card w-full px-4 py-3.5 text-[15px] outline-none focus:border-neutral-600 placeholder:text-neutral-600"
            placeholder="Käyttäjätunnus"
            value={user}
            onChange={(e) => setUser(e.target.value)}
            autoCapitalize="none"
            autoCorrect="off"
          />
          <input
            className="card w-full px-4 py-3.5 text-[15px] outline-none focus:border-neutral-600 placeholder:text-neutral-600"
            placeholder="Salasana"
            type="password"
            value={pass}
            onChange={(e) => setPass(e.target.value)}
          />
          {err && <div className="text-red-400 text-sm px-1">{err}</div>}
          <button
            disabled={busy || !url || !user || !pass}
            className="w-full py-3.5 rounded-2xl bg-white text-black font-medium text-[15px] disabled:opacity-40 active:scale-[0.98] transition"
          >
            {busy ? "Kirjaudutaan…" : "Kirjaudu"}
          </button>
        </form>
        <div className="text-neutral-600 text-xs mt-6 leading-relaxed">
          Sama tunnus kuin Wilmassa. Sessio pysyy elossa palvelimella — salasanaa ei tallenneta laitteelle.
        </div>
      </div>
    </div>
  );
}
