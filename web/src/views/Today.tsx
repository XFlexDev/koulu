import { useEffect, useMemo, useState } from "react";
import { api } from "../api";
import type { Week, Day } from "../api";

function nowMin() {
  const n = new Date();
  return n.getHours() * 60 + n.getMinutes();
}
function toMin(t?: string) {
  if (!t) return -1;
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
}
function todayStr() {
  return new Date().toISOString().slice(0, 10);
}

export default function Today() {
  const [week, setWeek] = useState<Week | null>(null);
  const [err, setErr] = useState("");

  useEffect(() => {
    api
      .schedule(todayStr())
      .then(setWeek)
      .catch((e) => setErr(e.message));
  }, []);

  const day: Day | null = useMemo(() => {
    if (!week) return null;
    return week.days.find((d) => d.date === todayStr()) || week.days[new Date().getDay() - 1] || null;
  }, [week]);

  const n = nowMin();
  const lessons = day?.lessons || [];
  const current = lessons.find((l) => toMin(l.start) <= n && toMin(l.end) > n);
  const next = lessons.find((l) => toMin(l.start) > n);
  const done = lessons.length > 0 && !current && !next;

  return (
    <div className="px-4 pt-6 pb-28 space-y-4 fadein">
      <div className="flex items-baseline justify-between">
        <div className="text-2xl font-semibold tracking-tight">
          {new Date().toLocaleDateString("fi-FI", { weekday: "long", day: "numeric", month: "numeric" })}
        </div>
      </div>

      {err && <div className="card p-4 text-red-400 text-sm">{err}</div>}
      {!week && !err && <div className="text-neutral-500 text-sm">Ladataan…</div>}

      {day && (
        <>
          {current && (
            <div className="card p-5 relative overflow-hidden">
              <div
                className="absolute left-0 top-0 bottom-0 w-1.5"
                style={{ background: current.color }}
              />
              <div className="text-xs text-neutral-500 uppercase tracking-wider mb-1">Nyt</div>
              <div className="text-xl font-semibold">{current.subject}</div>
              <div className="text-neutral-400 text-sm mt-1">
                {current.start}–{current.end}
                {current.room ? ` · ${current.room}` : ""}
                {current.teachers[0] ? ` · ${current.teachers[0]}` : ""}
              </div>
              <div className="mt-3 h-1 rounded-full bg-neutral-800 overflow-hidden">
                <div
                  className="h-full rounded-full transition-all"
                  style={{
                    background: current.color,
                    width: `${Math.min(
                      100,
                      Math.max(0, ((n - toMin(current.start)) / (toMin(current.end) - toMin(current.start))) * 100)
                    )}%`,
                  }}
                />
              </div>
              <div className="text-xs text-neutral-500 mt-1.5">
                {toMin(current.end) - n} min jäljellä
              </div>
            </div>
          )}

          {!current && next && !done && (
            <div className="card p-5 relative overflow-hidden">
              <div className="absolute left-0 top-0 bottom-0 w-1.5" style={{ background: next.color }} />
              <div className="text-xs text-neutral-500 uppercase tracking-wider mb-1">Seuraavaksi</div>
              <div className="text-xl font-semibold">{next.subject}</div>
              <div className="text-neutral-400 text-sm mt-1">
                klo {next.start}
                {next.room ? ` · ${next.room}` : ""} · {toMin(next.start) - n} min päästä
              </div>
            </div>
          )}

          {done && <div className="card p-5 text-neutral-400">Päivä ohi. 🎉</div>}
          {lessons.length === 0 && <div className="card p-5 text-neutral-400">Ei tunteja tänään.</div>}

          <div className="space-y-2">
            {lessons.map((l, i) => {
              const isCur = l === current;
              const past = toMin(l.end) <= n;
              return (
                <div
                  key={i}
                  className={`card px-4 py-3 flex items-center gap-3 ${past ? "opacity-40" : ""}`}
                >
                  <div className="w-1 h-10 rounded-full shrink-0" style={{ background: l.color }} />
                  <div className="flex-1 min-w-0">
                    <div className="font-medium truncate">{l.subject}</div>
                    <div className="text-xs text-neutral-500 truncate">
                      {l.room}
                      {l.teachers[0] ? ` · ${l.teachers[0]}` : ""}
                    </div>
                  </div>
                  <div className="text-sm text-neutral-400 tabular-nums shrink-0">
                    {l.start}–{l.end}
                  </div>
                  {isCur && (
                    <div
                      className="w-2 h-2 rounded-full animate-pulse shrink-0"
                      style={{ background: l.color }}
                    />
                  )}
                </div>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
}
