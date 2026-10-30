import 'package:flutter/material.dart';
import '../api.dart';

const folders = {
  'inbox': 'Saapuneet',
  'sent': 'Lähetetyt',
  'archive': 'Arkisto',
};

String _fmtTs(dynamic ts) {
  if (ts == null) return '';
  final s = ts.toString();
  return s.length > 16 ? s.substring(0, 16) : s;
}

String _stripHtml(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .trim();

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String folder = 'inbox';
  List<dynamic> msgs = [];
  bool loading = true;
  String? error;

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final m = await messages(folder);
      setState(() => msgs = m);
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

  void openCompose() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ComposeSheet(onSent: load),
    );
  }

  void openMessage(Map<String, dynamic> m) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MessageSheet(id: m['id'] as int),
    ).then((_) => load());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: openCompose,
        child: const Icon(Icons.edit_outlined),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
          children: [
            Text('Viestit',
                style:
                    t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                for (final e in folders.entries)
                  ButtonSegment(value: e.key, label: Text(e.value)),
              ],
              selected: {folder},
              onSelectionChanged: (s) {
                setState(() => folder = s.first);
                load();
              },
            ),
            const SizedBox(height: 8),
            if (loading)
              const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()))
            else if (error != null)
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(error!)))
            else ...[
              if (msgs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Ei viestejä',
                      style: t.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ),
              for (final m in msgs.cast<Map<String, dynamic>>())
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: (m['unread'] == true)
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: Color(0xFF8AB4F8),
                              shape: BoxShape.circle))
                      : const SizedBox(width: 10),
                  title: Text(m['subject'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: m['unread'] == true
                              ? FontWeight.w700
                              : FontWeight.w500)),
                  subtitle: Text(m['from'] ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(_fmtTs(m['timestamp']),
                      style: t.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                  onTap: () => openMessage(m),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class MessageSheet extends StatefulWidget {
  final int id;
  const MessageSheet({super.key, required this.id});
  @override
  State<MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<MessageSheet> {
  Map<String, dynamic>? msg;
  final replyCtrl = TextEditingController();
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    message(widget.id).then((m) => setState(() => msg = m)).catchError((e) {
      setState(() => error = e.toString());
    });
  }

  Future<void> sendReply() async {
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await reply(widget.id, replyCtrl.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          if (msg == null && error == null)
            const Center(child: CircularProgressIndicator())
          else if (error != null)
            Text(error!)
          else ...[
            Text(msg!['subject'] ?? '',
                style:
                    t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${msg!['from'] ?? ''}  ·  ${msg!['timestamp'] ?? ''}',
                style: t.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
            const Divider(height: 32),
            Text(_stripHtml(msg!['html'] ?? ''), style: t.bodyMedium),
            const SizedBox(height: 24),
            TextField(
              controller: replyCtrl,
              decoration: const InputDecoration(
                labelText: 'Vastaa',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: sending || replyCtrl.text.trim().isEmpty
                  ? null
                  : sendReply,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Lähetä'),
            ),
          ],
        ],
      ),
    );
  }
}

class ComposeSheet extends StatefulWidget {
  final VoidCallback onSent;
  const ComposeSheet({super.key, required this.onSent});
  @override
  State<ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<ComposeSheet> {
  List<dynamic> recips = [];
  final picked = <Map<String, dynamic>>[];
  final subject = TextEditingController();
  final body = TextEditingController();
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    recipients().then((r) => setState(() => recips = r)).catchError((e) {
      setState(() => error = e.toString());
    });
  }

  Future<void> sendMsg() async {
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await send(picked, subject.text, body.text);
      widget.onSent();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          Text('Uusi viesti',
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in picked)
                InputChip(
                  label: Text(r['name'] ?? ''),
                  onDeleted: () => setState(() => picked.remove(r)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final r in recips.cast<Map<String, dynamic>>())
                  if (!picked.contains(r))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r['name'] ?? ''),
                      subtitle: r['role'] != null
                          ? Text(r['role'], style: t.bodySmall)
                          : null,
                      onTap: () => setState(() => picked.add(r)),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: subject,
            decoration: const InputDecoration(
              labelText: 'Aihe',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: body,
            decoration: const InputDecoration(
              labelText: 'Viesti',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: sending ||
                    picked.isEmpty ||
                    subject.text.trim().isEmpty ||
                    body.text.trim().isEmpty
                ? null
                : sendMsg,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Lähetä'),
          ),
        ],
      ),
    );
  }
}
