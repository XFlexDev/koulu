import 'package:flutter/material.dart';

import '../api.dart';
import '../ui.dart';

class MoreScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MoreScreen({super.key, required this.onLogout});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  List<dynamic> examList = [];
  List<dynamic> assessmentList = [];
  List<dynamic> observations = [];
  bool loading = true;
  bool failed = false;
  bool loggingOut = false;

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final results = await Future.wait<dynamic>([
        exams(),
        assessments(),
        attendance(),
      ]);
      if (!mounted) return;
      setState(() {
        examList = results[0] as List<dynamic>;
        assessmentList = results[1] as List<dynamic>;
        observations =
            ((results[2] as Map<String, dynamic>)['observations']
                as List<dynamic>?) ??
            [];
      });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => loggingOut = true);
    await logout();
    if (mounted) widget.onLogout();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lisää')),
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
                message: 'Tietojen lataaminen epäonnistui.',
                onRetry: load,
              )
            else ...[
              _section(
                'Kokeet',
                examList,
                'Ei tulevia kokeita',
                (exam) => _examCard(context, exam),
              ),
              _section(
                'Arviointikeskustelut',
                assessmentList,
                'Ei arviointikeskusteluja',
                _assessmentCard,
              ),
              _section(
                'Poissaolot',
                observations,
                'Ei poissaolomerkintöjä',
                _observationCard,
              ),
              const SizedBox(height: 26),
              OutlinedButton.icon(
                onPressed: loggingOut ? null : _logout,
                icon: loggingOut
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: const Text('Kirjaudu ulos'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: KouluColors.text,
                  side: const BorderSide(color: KouluColors.border),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(
    String title,
    List<dynamic> items,
    String emptyText,
    Widget Function(Map<String, dynamic>) buildCard,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(title),
        if (items.isEmpty)
          EmptyState(emptyText)
        else
          for (final item in items.cast<Map<String, dynamic>>())
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: buildCard(item),
            ),
      ],
    );
  }

  Widget _examCard(BuildContext context, Map<String, dynamic> exam) {
    final title = valueOf(exam['name']).isEmpty
        ? valueOf(exam['course'])
        : valueOf(exam['name']);
    final details = [
      valueOf(exam['course']),
      valueOf(exam['time']),
      valueOf(exam['teacher']),
      valueOf(exam['info']),
    ].where((part) => part.isNotEmpty).join(' · ');
    return KouluCard(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => ExamPage(exam: exam)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            [
              cardDate(exam['date']),
              details,
            ].where((part) => part.isNotEmpty).join(' · '),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: KouluColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _assessmentCard(Map<String, dynamic> assessment) => KouluCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valueOf(assessment['name']).isEmpty
              ? 'Arviointikeskustelu'
              : valueOf(assessment['name']),
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          [
            valueOf(assessment['start']),
            valueOf(assessment['end']),
            valueOf(assessment['teacher']),
          ].where((part) => part.isNotEmpty).join(' · '),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: KouluColors.secondary),
        ),
      ],
    ),
  );

  Widget _observationCard(Map<String, dynamic> observation) => KouluCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valueOf(observation['timestamp']),
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          [
            valueOf(observation['type']),
            valueOf(observation['description']),
          ].where((part) => part.isNotEmpty).join(' · '),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: KouluColors.secondary),
        ),
      ],
    ),
  );
}

class ExamPage extends StatelessWidget {
  final Map<String, dynamic> exam;

  const ExamPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final details = <(String, String)>[
      ('Päivä', cardDate(exam['date'])),
      ('Aika', valueOf(exam['time'])),
      ('Kurssi', valueOf(exam['course'])),
      ('Opettaja', valueOf(exam['teacher'])),
      ('Lisätiedot', valueOf(exam['info'])),
    ].where((entry) => entry.$2.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Koe')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Text(
            valueOf(exam['name']).isEmpty
                ? valueOf(exam['course'])
                : valueOf(exam['name']),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          KouluCard(
            child: Column(
              children: [
                for (var i = 0; i < details.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          details[i].$1,
                          style: const TextStyle(color: KouluColors.secondary),
                        ),
                      ),
                      Expanded(child: Text(details[i].$2)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
