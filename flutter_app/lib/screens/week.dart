import 'package:flutter/material.dart';

import '../api.dart';
import '../ui.dart';
import 'today.dart' show fiDate, fmtDate, lessonColor, teacherNames, weekDays;

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  DateTime anchor = DateTime.now();
  Map<String, dynamic>? week;
  String? selectedDate;
  bool loading = true;
  bool failed = false;

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final data = await schedule(fmtDate(anchor));
      final days = (data['days'] as List<dynamic>? ?? [])
          .map((day) => Map<String, dynamic>.from(day as Map))
          .toList();
      final visibleDays = _visibleDays(days);
      final today = fmtDate(DateTime.now());
      final currentDay = visibleDays.any((day) => day['date'] == selectedDate);
      if (!mounted) return;
      setState(() {
        week = data;
        if (!currentDay) {
          selectedDate = visibleDays.any((day) => day['date'] == today)
              ? today
              : visibleDays.isEmpty
              ? null
              : visibleDays.first['date'] as String?;
        }
      });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  void shiftWeek(int offset) {
    anchor = anchor.add(Duration(days: offset));
    selectedDate = null;
    load();
  }

  @override
  Widget build(BuildContext context) {
    final days = _visibleDays(
      ((week?['days'] as List<dynamic>?) ?? [])
          .map((day) => Map<String, dynamic>.from(day as Map))
          .toList(),
    );
    Map<String, dynamic>? selectedDay;
    for (final day in days) {
      if (day['date'] == selectedDate) {
        selectedDay = day;
        break;
      }
    }
    final lessons = ((selectedDay?['lessons'] as List<dynamic>?) ?? [])
        .map((lesson) => Map<String, dynamic>.from(lesson as Map))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Viikko ${_weekNumber()}'),
        actions: [
          IconButton(
            tooltip: 'Edellinen viikko',
            onPressed: () => shiftWeek(-7),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Seuraava viikko',
            onPressed: () => shiftWeek(7),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.all(44),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (failed)
              RetryState(
                message: 'Lukujärjestyksen lataaminen epäonnistui.',
                onRetry: load,
              )
            else ...[
              _dayPicker(days),
              const SizedBox(height: 20),
              if (selectedDay != null)
                Text(
                  fiDate(DateTime.parse(valueOf(selectedDay['date']))),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 8),
              if (lessons.isEmpty)
                const EmptyState('Ei tunteja')
              else
                for (final lesson in lessons) _lessonRow(lesson),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dayPicker(List<Map<String, dynamic>> days) {
    if (days.isEmpty) return const EmptyState('Ei lukujärjestystä');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final day in days) ...[
            if (day != days.first) const SizedBox(width: 8),
            _dayChip(day),
          ],
        ],
      ),
    );
  }

  Widget _dayChip(Map<String, dynamic> day) {
    final date = valueOf(day['date']);
    final weekday = (day['weekday'] as int? ?? 1).clamp(1, 7);
    final dayNumber = date.length >= 10 ? date.substring(8, 10) : '';
    final selected = date == selectedDate;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => selectedDate = date),
      label: SizedBox(
        width: 38,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(weekDays[weekday - 1]),
            Text(
              dayNumber,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      labelStyle: TextStyle(
        color: selected ? KouluColors.accent : KouluColors.secondary,
      ),
      selectedColor: KouluColors.navigationIndicator,
      backgroundColor: KouluColors.card,
      side: const BorderSide(color: KouluColors.border),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(vertical: 6),
    );
  }

  Widget _lessonRow(Map<String, dynamic> lesson) {
    final isBreak = lesson['break'] == true;
    final details = [
      valueOf(lesson['room']),
      teacherNames(lesson),
    ].where((part) => part.isNotEmpty).join(' · ');
    return Opacity(
      opacity: isBreak ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valueOf(lesson['start']),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    valueOf(lesson['end']),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: KouluColors.secondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 3,
              height: 42,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isBreak ? KouluColors.secondary : lessonColor(lesson),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valueOf(lesson['subject']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (isBreak
                                ? Theme.of(context).textTheme.bodySmall
                                : Theme.of(context).textTheme.bodyMedium)
                            ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KouluColors.secondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _visibleDays(List<Map<String, dynamic>> days) =>
      days.where((day) {
        final weekday = day['weekday'] as int? ?? 1;
        final lessons = (day['lessons'] as List<dynamic>?) ?? [];
        return weekday <= 5 || lessons.isNotEmpty;
      }).toList();

  int _weekNumber() {
    final weekStart = DateTime.tryParse(valueOf(week?['week_start']));
    if (weekStart == null) return 1;
    final thursday = weekStart.add(const Duration(days: 3));
    final januaryFourth = DateTime(thursday.year, 1, 4);
    final firstMonday = januaryFourth.subtract(
      Duration(days: januaryFourth.weekday - 1),
    );
    return thursday.difference(firstMonday).inDays ~/ 7 + 1;
  }
}
