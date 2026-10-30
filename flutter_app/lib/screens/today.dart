import 'package:flutter/material.dart';
import '../api.dart';

const _fiDays = [
  'maanantai', 'tiistai', 'keskiviikko', 'torstai',
  'perjantai', 'lauantai', 'sunnuntai'
];

Color lessonColor(Map<String, dynamic> l) {
  final c = l['color'] as String?;
  if (c != null && c.startsWith('#')) {
    return Color(int.parse('FF${c.substring(1)}', radix: 16));
  }
  return const Color(0xFF4ADE80);
}

List<dynamic> lessonsOf(Map<String, dynamic>? day) =>
    (day?['lessons'] as List<dynamic>?) ?? [];

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fiDate(DateTime d) => '${_fiDays[d.weekday - 1]} ${d.day}.${d.month}.';

String teacherNames(Map<String, dynamic> l) =>
    ((l['teachers'] as List<dynamic>?) ?? []).join(', ');

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Map<String, dynamic>? day;
  bool loading = true;
  String? error;

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final w = await schedule(fmtDate(DateTime.now()));
      final days = (w['days'] as List<dynamic>?) ?? [];
      final todayIso = fmtDate(DateTime.now());
      setState(() {
        final i = days.indexWhere((d) => d['date'] == todayIso);
        day = i >= 0 ? Map<String, dynamic>.from(days[i]) : null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lessons = lessonsOf(day);
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;

    int toMin(String s) {
      final p = s.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    Map<String, dynamic>? current;
    Map<String, dynamic>? next;
    for (final l in lessons.cast<Map<String, dynamic>>()) {
      final s = toMin(l['start'] ?? '0:00');
      final e = toMin(l['end'] ?? '0:00');
      if (nowMin >= s && nowMin < e) {
        current = l;
      } else if (s > nowMin && next == null) {
        next = l;
      }
    }
    final hero = current ?? next;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
          children: [
            Text(fiDate(DateTime.now()),
                style:
                    t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (loading)
              const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()))
            else if (error != null)
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(error!)))
            else ...[
              if (hero != null)
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current != null ? 'NYT' : 'SEURAAVAKSI',
                            style: t.labelSmall?.copyWith(
                                color: lessonColor(hero),
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(hero['subject'] ?? 'Tunti',
                            style: t.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                            '${hero['start']}–${hero['end']}  ·  ${hero['room'] ?? ''}  ·  ${teacherNames(hero)}',
                            style: t.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        if (current != null) ...[
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: (nowMin - toMin(hero['start'])) /
                                (toMin(hero['end']) - toMin(hero['start'])),
                            color: lessonColor(hero),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                        lessons.isEmpty ? 'Ei tunteja tänään' : 'Päivä ohi',
                        style: t.titleMedium),
                  ),
                ),
              const SizedBox(height: 12),
              for (final l in lessons.cast<Map<String, dynamic>>())
                Builder(builder: (_) {
                  final past = toMin(l['end'] ?? '0:00') < nowMin;
                  return Opacity(
                    opacity: past ? 0.45 : 1,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                            color: lessonColor(l), shape: BoxShape.circle),
                      ),
                      title: Text(l['subject'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([
                        if (l['room'] != null && l['room'] != '') l['room'],
                        if (teacherNames(l).isNotEmpty) teacherNames(l),
                      ].join(' · ')),
                      trailing: Text('${l['start']}–${l['end']}',
                          style: t.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}
