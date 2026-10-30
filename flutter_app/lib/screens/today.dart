import 'package:flutter/material.dart';

import '../api.dart';
import '../ui.dart';
import 'announcements.dart';
import 'messages.dart';
import 'more.dart';

const _fiDays = [
  'maanantai',
  'tiistai',
  'keskiviikko',
  'torstai',
  'perjantai',
  'lauantai',
  'sunnuntai',
];

const weekDays = ['Ma', 'Ti', 'Ke', 'To', 'Pe', 'La', 'Su'];

String fmtDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String fiDate(DateTime date) =>
    '${_fiDays[date.weekday - 1]} ${date.day}.${date.month}.';

List<dynamic> lessonsOf(Map<String, dynamic>? day) =>
    (day?['lessons'] as List<dynamic>?) ?? [];

String teacherNames(Map<String, dynamic> lesson) =>
    ((lesson['teachers'] as List<dynamic>?) ?? []).join(', ');

Color lessonColor(Map<String, dynamic> lesson) {
  final raw = lesson['color'] as String?;
  if (raw == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(raw)) {
    return KouluColors.accent;
  }
  final color = Color(int.parse('FF${raw.substring(1)}', radix: 16));
  final r = color.r;
  final g = color.g;
  final b = color.b;
  final max = [r, g, b].reduce((a, b) => a > b ? a : b);
  final min = [r, g, b].reduce((a, b) => a < b ? a : b);
  var hue = 0.0;
  if (max != min) {
    if (max == r) {
      hue = 60 * (((g - b) / (max - min)) % 6);
    } else if (max == g) {
      hue = 60 * ((b - r) / (max - min) + 2);
    } else {
      hue = 60 * ((r - g) / (max - min) + 4);
    }
  }
  if (hue < 0) hue += 360;
  return hue >= 190 && hue <= 265 ? KouluColors.accent : color;
}

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> profile = {};
  Map<String, dynamic>? today;
  List<dynamic> inbox = [];
  List<dynamic> examList = [];
  List<dynamic> newsList = [];
  bool loading = true;
  bool failed = false;

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final results = await Future.wait<dynamic>([
        me(),
        messages('inbox'),
        schedule(fmtDate(DateTime.now())),
        exams(),
        news(),
      ]);
      final scheduleData = results[2] as Map<String, dynamic>;
      final todayDate = fmtDate(DateTime.now());
      final days = (scheduleData['days'] as List<dynamic>?) ?? [];
      final todayIndex = days.indexWhere((day) => day['date'] == todayDate);
      if (!mounted) return;
      setState(() {
        profile = results[0] as Map<String, dynamic>;
        inbox = results[1] as List<dynamic>;
        today = todayIndex < 0
            ? null
            : Map<String, dynamic>.from(days[todayIndex] as Map);
        examList = results[3] as List<dynamic>;
        newsList = results[4] as List<dynamic>;
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

  @override
  Widget build(BuildContext context) {
    final account = (profile['account'] as Map?) ?? {};
    final fullName = [
      account['firstname'],
      account['lastname'],
    ].where((part) => part != null && part.toString().isNotEmpty).join(' ');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: KouluColors.header,
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.paddingOf(context).top + 20,
                  24,
                  24,
                ),
                child: Column(
                  children: [
                    ProfileAvatar(
                      name: fullName,
                      imageUrl: photoUrl,
                      headers: apiAuthHeaders(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName.isEmpty ? 'koulu' : fullName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: KouluColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(36),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : failed
                    ? RetryState(
                        message: 'Tietojen lataaminen epäonnistui.',
                        onRetry: load,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _messageSection(),
                          _todaySection(),
                          _examSection(),
                          _newsSection(),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageSection() {
    final items = inbox.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading('Viestit', onTap: () => widget.onNavigate(1)),
        if (items.isEmpty)
          const EmptyState('Ei viestejä')
        else
          _cardRow(
            items,
            (item) => _summaryCard(
              title: valueOf(item['subject']),
              preview: valueOf(item['from']),
              date: cardDate(item['timestamp']),
              onTap: () => Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => MessagePage(id: item['id'] as int),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _todaySection() {
    final lessons = lessonsOf(today)
        .where((lesson) => lesson['break'] != true)
        .cast<Map<String, dynamic>>();
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading('Tänään', onTap: () => widget.onNavigate(3)),
        if (lessons.isEmpty)
          const EmptyState('Ei tunteja tänään')
        else
          for (final lesson in lessons) _todayLesson(lesson, nowMinutes),
      ],
    );
  }

  Widget _todayLesson(Map<String, dynamic> lesson, int nowMinutes) {
    final start = _minutes(valueOf(lesson['start']));
    final end = _minutes(valueOf(lesson['end']));
    final current =
        start != null && end != null && nowMinutes >= start && nowMinutes < end;
    final room = valueOf(lesson['room']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              valueOf(lesson['start']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: current ? KouluColors.accent : KouluColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: current ? KouluColors.accent : lessonColor(lesson),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valueOf(lesson['subject']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (room.isNotEmpty)
                    Text(
                      room,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: KouluColors.secondary),
                    ),
                ],
              ),
            ),
          ),
          if (current)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.circle, size: 7, color: KouluColors.accent),
            ),
        ],
      ),
    );
  }

  Widget _examSection() {
    final items = examList.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading('Kokeet', onTap: () => widget.onNavigate(4)),
        if (items.isEmpty)
          const EmptyState('Ei tulevia kokeita')
        else
          _cardRow(
            items,
            (item) => _summaryCard(
              title: valueOf(item['name']).isEmpty
                  ? valueOf(item['course'])
                  : valueOf(item['name']),
              preview: [
                valueOf(item['course']),
                valueOf(item['time']),
              ].where((part) => part.isNotEmpty).join(' · '),
              date: cardDate(item['date']),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => ExamPage(exam: item)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _newsSection() {
    final items = newsList.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading('Tiedotteet', onTap: () => widget.onNavigate(2)),
        if (items.isEmpty)
          const EmptyState('Ei tiedotteita')
        else
          _cardRow(
            items,
            (item) => _summaryCard(
              title: valueOf(item['title']),
              preview: valueOf(item['description']),
              date: cardDate(item['date']),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => NewsPage(id: item['id'] as int),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _cardRow(List<dynamic> items, Widget Function(dynamic) buildCard) =>
      SizedBox(
        height: 152,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) =>
              SizedBox(width: 260, child: buildCard(items[index])),
        ),
      );

  Widget _summaryCard({
    required String title,
    required String preview,
    required String date,
    required VoidCallback onTap,
  }) => KouluCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Text(
            preview.isEmpty ? ' ' : preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: KouluColors.secondary, height: 1.4),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            date,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: KouluColors.secondary),
          ),
        ),
      ],
    ),
  );

  int? _minutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}
