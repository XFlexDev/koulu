import 'package:flutter/material.dart';
import '../api.dart';

class MoreScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MoreScreen({super.key, required this.onLogout});
  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  Map<String, dynamic>? user;
  List<dynamic> examList = [];
  List<dynamic> newsList = [];
  List<dynamic> assessList = [];
  List<dynamic> obsList = [];
  bool loading = true;

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        me().catchError((_) => <String, dynamic>{}),
        exams().catchError((_) => []),
        news().catchError((_) => []),
        assessments().catchError((_) => []),
        attendance().catchError((_) => <String, dynamic>{}),
      ]);
      setState(() {
        user = results[0] as Map<String, dynamic>;
        examList = results[1] as List<dynamic>;
        newsList = results[2] as List<dynamic>;
        assessList = results[3] as List<dynamic>;
        obsList = ((results[4] as Map<String, dynamic>)['observations']
                as List<dynamic>?) ??
            [];
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Widget section(String title, List<Widget> items) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Text(title.toUpperCase(),
              style: t.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700)),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Ei mitään',
                style: t.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          )
        else
          ...items,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final name = (user?['account'] as Map?)?['name'] as String? ??
        (user?['account'] as Map?)?['username'] as String? ??
        '';
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
          children: [
            Text(name.isEmpty ? 'Lisää' : name,
                style:
                    t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (loading)
              const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()))
            else ...[
              section('Kokeet', [
                for (final e in examList.cast<Map<String, dynamic>>())
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e['name'] ?? e['course'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        [e['date'], e['info']]
                            .where((x) => x != null && x != '')
                            .join('  ·  ')),
                  ),
              ]),
              section('Arviointikeskustelut', [
                for (final a in assessList.cast<Map<String, dynamic>>())
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(a['name'] ?? a['course'] ?? ''),
                    subtitle: Text(
                        [a['start'], a['end'], a['teacher']]
                            .where((x) => x != null && x != '')
                            .join('  ·  ')),
                  ),
              ]),
              section('Poissaolot', [
                for (final o in obsList.cast<Map<String, dynamic>>())
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(o['timestamp'] ?? ''),
                    subtitle: Text(
                        [o['type'], o['description']]
                            .where((x) => x != null && x != '')
                            .join('  ·  ')),
                  ),
              ]),
              section('Tiedotteet', [
                for (final n in newsList.cast<Map<String, dynamic>>())
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(n['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(n['date'] ?? ''),
                    trailing: (n['sticky'] == true || n['important'] == true)
                        ? const Chip(
                            label: Text('Tärkeä'),
                            visualDensity: VisualDensity.compact)
                        : null,
                  ),
              ]),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () async {
                  await logout();
                  widget.onLogout();
                },
                style: FilledButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.error,
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Kirjaudu ulos'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
