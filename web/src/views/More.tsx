import { useEffect, useState } from "react";
import { api } from "../api";

type Section = "menu" | "exams" | "homework" | "absences" | "news";

export default function More({ onLogout }: { onLogout: () => void }) {
  const [sec, setSec] = useState<Section>("menu");
  const [me, setMe] = useState<any>(null);

  useEffect(() => {
    api.me().then(setMe).catch(() => {});
  }, []);

  if (sec !== "menu") {
    return (
      <div className="px-4 pt-6 pb-28 fadein">
        <button onClick={() => setSec("menu")} className="text-sm text-neutral-400 mb-4">
          ← Takaisin
        </button>
        {sec === "exams" && <Exams />}
        {sec === "homework" && <Homework />}
        {sec === "absences" && <Absences />}
        {sec === "news" && <News />}
      </div>
    );
  }

  const item = (label: string, sub: string, s: Section) => (
    <button
      onClick={() => setSec(s)}
      className="card w-full px-5 py-4 text-left flex items-center justify-between active:scale-[0.99] transition"
    >
      <div>
        <div className="font-medium">{label}</div>
        <div className="text-xs text-neutral-500 mt-0.5">{sub}</div>
      </div>
      <div className="text-neutral-600">›</div>
    </button>
  );

  return (
    <div className="px-4 pt-6 pb-28 space-y-2 fadein">
      <div className="text-2xl font-semibold tracking-tight mb-4">Lisää</div>
      {item("Kokeet", "Tulevat kokeet ja tentit", "exams")}
      {item("Kotitehtävät", "Tehtävät kurssikohtaisesti", "homework")}
      {item("Poissaolot", "Tuntimerkinnät ja selvitykset", "absences")}
      {item("Tiedotteet", "Koulun tiedotteet", "news")}

      <div className="card p-5 mt-6">
        <div className="font-medium">
          {me?.account ? `${me.account.firstname ?? ""} ${me.account.lastname ?? ""}`.trim() || me.account.username : "…"}
        </div>
        <div className="text-xs text-neutral-500 mt-0.5">
          {me?.roles?.[0]?.name}
          {me?.roles?.[0]?.type ? ` · ${me.roles[0].type}` : ""}
        </div>
        {me?.roles?.length > 1 && (
          <div className="text-xs text-neutral-600 mt-2">
            {me.roles.length} roolia — roolien vaihto tulossa.
          </div>
        )}
        <button
          onClick={async () => {
            await api.logout().catch(() => {});
            onLogout();
          }}
          className="mt-4 text-sm text-red-400"
        >
          Kirjaudu ulos
        </button>
      </div>
    </div>
  );
}

function Exams() {
  const [exams, setExams] = useState<any[] | null>(null);
  const [err, setErr] = useState("");
  useEffect(() => {
    api.exams().then((d) => setExams(d.exams)).catch((e) => setErr(e.message));
  }, []);
  return (
    <>
      <div className="text-xl font-semibold mb-4">Kokeet</div>
      {err && <div className="card p-4 text-red-400 text-sm">{err}</div>}
      {!exams && !err && <div className="text-neutral-500 text-sm">Ladataan…</div>}
      {exams?.length === 0 && <div className="card p-5 text-neutral-400">Ei tulevia kokeita.</div>}
      <div className="space-y-2">
        {exams?.map((e, i) => (
          <div key={i} className="card p-4">
            <div className="flex justify-between gap-3">
              <div className="min-w-0">
                <div className="font-medium truncate">{e.course}</div>
                {e.name && <div className="text-sm text-neutral-300 mt-0.5">{e.name}</div>}
                {e.info && <div className="text-xs text-neutral-500 mt-1">{e.info}</div>}
                {!!e.teachers?.length && (
                  <div className="text-xs text-neutral-600 mt-1">{e.teachers.join(", ")}</div>
                )}
              </div>
              <div className="text-sm text-neutral-300 tabular-nums shrink-0">
                {e.date ? new Date(e.date).toLocaleDateString("fi-FI") : ""}
              </div>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

function Homework() {
  const [groups, setGroups] = useState<any[] | null>(null);
  const [err, setErr] = useState("");
  useEffect(() => {
    api.groups().then((d) => setGroups(d.groups)).catch((e) => setErr(e.message));
  }, []);
  const withHw = (groups || []).filter((g) => g.homework?.length);
  return (
    <>
      <div className="text-xl font-semibold mb-4">Kotitehtävät</div>
      {err && <div className="card p-4 text-red-400 text-sm">{err}</div>}
      {!groups && !err && <div className="text-neutral-500 text-sm">Ladataan…</div>}
      {groups && withHw.length === 0 && <div className="card p-5 text-neutral-400">Ei läksyjä. 🎉</div>}
      <div className="space-y-3">
        {withHw.map((g, i) => (
          <div key={i} className="card p-4">
            <div className="font-medium mb-2">{g.caption}</div>
            <div className="space-y-1.5">
              {g.homework.map((h: any, j: number) => (
                <div key={j} className="flex justify-between gap-3 text-sm">
                  <div className="text-neutral-300">{h.Homework || h.homework || h.Info || ""}</div>
                  <div className="text-neutral-500 tabular-nums shrink-0">
                    {h.Date ? new Date(h.Date).toLocaleDateString("fi-FI") : ""}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

function Absences() {
  const [data, setData] = useState<any>(null);
  const [err, setErr] = useState("");
  const [excusing, setExcusing] = useState<any | null>(null);
  const [excuseType, setExcuseType] = useState<number | null>(null);
  const [excuseText, setExcuseText] = useState("");

  useEffect(() => {
    api.attendance().then(setData).catch((e) => setErr(e.message));
  }, []);

  async function save() {
    if (!excusing || excuseType === null) return;
    try {
      await api.excuse([excusing.id], excuseType, excuseText);
      setExcusing(null);
      setExcuseType(null);
      setExcuseText("");
      api.attendance().then(setData);
    } catch (e: any) {
      alert(e.message);
    }
  }

  return (
    <>
      <div className="text-xl font-semibold mb-4">Poissaolot</div>
      {err && <div className="card p-4 text-red-400 text-sm">{err}</div>}
      {!data && !err && <div className="text-neutral-500 text-sm">Ladataan…</div>}
      {data?.observations?.length === 0 && (
        <div className="card p-5 text-neutral-400">Ei merkintöjä.</div>
      )}
      <div className="space-y-2">
        {data?.observations?.map((o: any) => (
          <div key={o.id} className="card p-4">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0">
                <div className="font-medium">{o.course}</div>
                <div className="text-xs text-neutral-500 mt-0.5">
                  {o.timestamp} · {o.duration ? `${o.duration} min` : ""} {o.teacher ? `· ${o.teacher}` : ""}
                </div>
              </div>
              <div
                className="text-xs px-2.5 py-1 rounded-full shrink-0"
                style={{ background: `${o.color}22`, color: o.color === "#FFFFFF" ? "#fff" : o.color }}
              >
                {o.type || o.short}
              </div>
            </div>
            {data.allow_excuse && o.requires_clearance && (
              <button
                onClick={() => setExcusing(o)}
                className="mt-3 text-sm text-blue-400"
              >
                Selvitä →
              </button>
            )}
          </div>
        ))}
      </div>

      {excusing && (
        <div className="fixed inset-0 z-50 flex flex-col bg-black/60" onClick={() => setExcusing(null)}>
          <div
            className="mt-auto bg-[#0c0c0d] border-t border-neutral-800 rounded-t-3xl p-5 sheet-in"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="text-lg font-semibold mb-1">Selvitä poissaolo</div>
            <div className="text-sm text-neutral-500 mb-4">
              {excusing.course} · {excusing.timestamp}
            </div>
            <div className="space-y-1.5 mb-3">
              {(data.excuse_types || []).map((t: any) => (
                <button
                  key={t.id}
                  onClick={() => setExcuseType(t.id)}
                  className={`card w-full px-4 py-3 text-left text-sm ${
                    excuseType === t.id ? "border-white" : ""
                  }`}
                >
                  {t.caption}
                </button>
              ))}
            </div>
            <textarea
              className="card w-full px-4 py-3 text-sm outline-none min-h-20 mb-3"
              placeholder="Lisätiedot…"
              value={excuseText}
              onChange={(e) => setExcuseText(e.target.value)}
            />
            <button
              onClick={save}
              disabled={excuseType === null}
              className="w-full py-3.5 rounded-2xl bg-white text-black font-medium text-sm disabled:opacity-40"
            >
              Lähetä selvitys
            </button>
          </div>
        </div>
      )}
    </>
  );
}

function News() {
  const [news, setNews] = useState<any[] | null>(null);
  const [err, setErr] = useState("");
  useEffect(() => {
    api.news().then((d) => setNews(d.news)).catch((e) => setErr(e.message));
  }, []);
  return (
    <>
      <div className="text-xl font-semibold mb-4">Tiedotteet</div>
      {err && <div className="card p-4 text-red-400 text-sm">{err}</div>}
      {!news && !err && <div className="text-neutral-500 text-sm">Ladataan…</div>}
      {news?.length === 0 && <div className="card p-5 text-neutral-400">Ei tiedotteita.</div>}
      <div className="space-y-2">
        {news?.map((n, i) => (
          <div key={i} className="card p-4">
            <div className="font-medium">{n.topic}</div>
            <div className="text-sm text-neutral-300 mt-1">{n.description}</div>
            <div className="text-xs text-neutral-600 mt-2">
              {n.creator} · {n.start}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
