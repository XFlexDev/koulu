import 'package:flutter/material.dart';
import '../api.dart';
import 'today.dart' show lessonColor, fmtDate, teacherNames;

const _weekdays = ['Ma', 'Ti', 'Ke', 'To', 'Pe', 'La', 'Su'];

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});
  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  DateTime anchor = DateTime.now();
  Map<String, dynamic>? week;
  int selected = 0;
  bool loading = true;
  String? error;

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final w = await schedule(fmtDate(anchor));
      final days = (w['days'] as List<dynamic>?) ?? [];
      setState(() {
        week = w;
        if (days.isNotEmpty) {
          final today = fmtDate(DateTime.now());
          final i = days.indexWhere((d) => d['date'] == today);
          selected = i >= 0 ? i : 0;
        } else {
          selected = 0;
        }
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

  void shift(int days) {
    anchor = anchor.add(Duration(days: days));
    load();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final days = ((week?['days'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();
    final day = days.isNotEmpty ? days[selected.clamp(0, days.length - 1)] : null;
    final lessons = ((day?['lessons'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Viikko',
                    style:
                        t.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton.filledTonal(
                    onPressed: () => shift(-7),
                    icon: const Icon(Icons.chevron_left)),
                IconButton.filledTonal(
                    onPressed: () => shift(7),
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 16),
            if (loading)
              const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()))
            else if (error != null)
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(error!)))
            else ...[
              SegmentedButton<int>(
                segments: [
                  for (var i = 0; i < days.length; i++)
                    ButtonSegment(
                      value: i,
                      label: Text(
                          _weekdays[((days[i]['weekday'] as int? ?? 1) - 1)
                              .clamp(0, 6)]),
                    ),
                ],
                selected: {selected},
                onSelectionChanged: (s) => setState(() => selected = s.first),
              ),
              const SizedBox(height: 8),
              if (day != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                      '${_weekdays[((day['weekday'] as int? ?? 1) - 1).clamp(0, 6)]} ${day['date'] ?? ''}',
                      style: t.titleSmall),
                ),
              if (lessons.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Ei tunteja',
                      style: t.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ),
              for (final l in lessons)
                ListTile(
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
            ],
          ],
        ),
      ),
    );
  }
}
