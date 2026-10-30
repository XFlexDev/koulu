import { useEffect, useState } from "react";
import { api } from "../api";
import type { Week, Day } from "../api";

const WD = ["Ma", "Ti", "Ke", "To", "Pe", "La", "Su"];

function mondayOf(d: Date) {
  const m = new Date(d);
  m.setDate(m.getDate() - ((m.getDay() + 6) % 7));
  return m.toISOString().slice(0, 10);
}

export default function WeekView() {
  const [anchor, setAnchor] = useState(mondayOf(new Date()));
  const [week, setWeek] = useState<Week | null>(null);
  const [err, setErr] = useState("");

  useEffect(() => {
    setWeek(null);
    api
      .schedule(anchor)
      .then(setWeek)
      .catch((e) => setErr(e.message));
  }, [anchor]);

  function shift(days: number) {
    const d = new Date(anchor);
    d.setDate(d.getDate() + days);
    setAnchor(d.toISOString().slice(0, 10));
  }

  const today = new Date().toISOString().slice(0, 10);
  const wkStart = week?.days[0]?.date;
  const wkNum = wkStart
    ? (() => {
        const d = new Date(wkStart);
        const jan1 = new Date(d.getFullYear(), 0, 1);
        return Math.ceil(((d.getTime() - jan1.getTime()) / 86400000 + jan1.getDay() + 1) / 7);
      })()
    : null;

  return (
    <div className="px-4 pt-6 pb-28 fadein">
      <div className="flex items-center justify-between mb-4">
        <div className="text-2xl font-semibold tracking-tight">Viikko{wkNum ? ` ${wkNum}` : ""}</div>
        <div className="flex gap-2">
          <button onClick={() => shift(-7)} className="card px-3.5 py-2 text-sm text-neutral-300 active:scale-95 transition">
            ←
          </button>
          <button
            onClick={() => setAnchor(mondayOf(new Date()))}
            className="card px-3.5 py-2 text-sm text-neutral-300 active:scale-95 transition"
          >
            Nyt
          </button>
          <button onClick={() => shift(7)} className="card px-3.5 py-2 text-sm text-neutral-300 active:scale-95 transition">
            →
          </button>
        </div>
      </div>

      {err && <div className="card p-4 text-red-400 text-sm">{err}</div>}
      {!week && !err && <div className="text-neutral-500 text-sm">Ladataan…</div>}

      {week && (
        <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4">
          {week.days.slice(0, 7).map((d: Day) => {
            const isToday = d.date === today;
            const dd = new Date(d.date);
            return (
              <div
                key={d.date}
                className={`shrink-0 w-[72px] rounded-2xl p-2 flex flex-col gap-1.5 ${
                  isToday ? "bg-[#151517] border border-neutral-700" : "bg-[#0a0a0b] border border-neutral-900"
                }`}
              >
                <div className="text-center">
                  <div className={`text-[11px] uppercase tracking-wide ${isToday ? "text-white" : "text-neutral-500"}`}>
                    {WD[d.weekday - 1]}
                  </div>
                  <div className={`text-sm font-medium ${isToday ? "" : "text-neutral-300"}`}>
                    {dd.getDate()}.{dd.getMonth() + 1}.
                  </div>
                </div>
                {d.lessons.length === 0 && <div className="flex-1" />}
                {d.lessons.map((l, i) => (
                  <div
                    key={i}
                    className="rounded-lg px-1.5 py-1.5 text-[10px] leading-tight"
                    style={{ background: `${l.color}22`, borderLeft: `2px solid ${l.color}` }}
                    title={`${l.subject} ${l.start}–${l.end}`}
                  >
                    <div className="font-medium text-neutral-100 truncate">{l.code || l.subject}</div>
                    <div className="text-neutral-500 tabular-nums">{l.start}</div>
                  </div>
                ))}
              </div>
            );
          })}
        </div>
      )}

      {/* Day detail under the strip: tap-equivalent — show today or first day with lessons */}
      {week && (
        <DayDetail week={week} today={today} />
      )}
    </div>
  );
}

function DayDetail({ week, today }: { week: Week; today: string }) {
  const [sel, setSel] = useState<string | null>(null);
  const day =
    week.days.find((d) => d.date === sel) ||
    week.days.find((d) => d.date === today) ||
    week.days.find((d) => d.lessons.length) ||
    week.days[0];

  return (
    <div className="mt-4">
      <div className="flex gap-1.5 mb-3">
        {week.days.slice(0, 7).map((d) => (
          <button
            key={d.date}
            onClick={() => setSel(d.date)}
            className={`flex-1 py-1.5 rounded-xl text-xs ${
              d.date === day.date ? "bg-white text-black font-semibold" : "bg-[#0a0a0b] text-neutral-400"
            }`}
          >
            {WD[d.weekday - 1]}
          </button>
        ))}
      </div>
      <div className="space-y-2">
        {day.lessons.length === 0 && <div className="card p-5 text-neutral-400">Vapaapäivä.</div>}
        {day.lessons.map((l, i) => (
          <div key={i} className="card px-4 py-3.5">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0">
                <div className="font-medium">{l.subject}</div>
                <div className="text-xs text-neutral-500 mt-0.5">
                  {l.room}
                  {l.teachers.length ? ` · ${l.teachers.join(", ")}` : ""}
                  {l.class ? ` · ${l.class}` : ""}
                </div>
                {l.info && <div className="text-xs text-neutral-500 mt-1">{l.info}</div>}
              </div>
              <div className="text-sm text-neutral-400 tabular-nums shrink-0">
                {l.start}–{l.end}
              </div>
            </div>
            <div className="mt-2 h-0.5 rounded-full" style={{ background: l.color }} />
          </div>
        ))}
      </div>
    </div>
  );
}
