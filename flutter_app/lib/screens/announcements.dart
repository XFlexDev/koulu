import 'package:flutter/material.dart';

import '../api.dart';
import '../ui.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<dynamic> items = [];
  bool loading = true;
  bool failed = false;

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final result = await news();
      if (mounted) setState(() => items = result);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tiedotteet')),
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
                message: 'Tiedotteiden lataaminen epäonnistui.',
                onRetry: load,
              )
            else if (items.isEmpty)
              const EmptyState('Ei tiedotteita')
            else
              for (final item in items.cast<Map<String, dynamic>>())
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KouluCard(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsPage(id: item['id'] as int),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                valueOf(item['title']),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (item['sticky'] == true ||
                                item['important'] == true) ...[
                              const SizedBox(width: 8),
                              const _ImportantChip(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            valueOf(item['date']),
                            valueOf(item['author']),
                          ].where((part) => part.isNotEmpty).join(' · '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: KouluColors.secondary),
                        ),
                        if (valueOf(item['description']).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            valueOf(item['description']),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: KouluColors.secondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class NewsPage extends StatefulWidget {
  final int id;

  const NewsPage({super.key, required this.id});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  Map<String, dynamic>? item;
  bool loading = true;
  bool failed = false;

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final result = await newsItem(widget.id);
      if (mounted) setState(() => item = result);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          valueOf(item?['title']).isEmpty ? 'Tiedote' : valueOf(item?['title']),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : failed
          ? RetryState(
              message: 'Tiedotteen avaaminen epäonnistui.',
              onRetry: load,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(
                  valueOf(item?['title']),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                KouluCard(
                  child: SelectableText(
                    stripHtml(valueOf(item?['body'])),
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(height: 1.55),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ImportantChip extends StatelessWidget {
  const _ImportantChip();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: KouluColors.navigationIndicator,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        'Tärkeä',
        style: TextStyle(
          color: KouluColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
