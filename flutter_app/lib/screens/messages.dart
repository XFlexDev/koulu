import 'package:flutter/material.dart';

import '../api.dart';
import '../ui.dart';

const _folders = ['inbox', 'sent', 'archive'];
const _folderLabels = ['Saapuneet', 'Lähetetyt', 'Arkisto'];

String _formatTimestamp(dynamic timestamp) {
  final text = valueOf(timestamp);
  return text.length > 16 ? text.substring(0, 16) : text;
}

String _stripHtml(String html) => stripHtml(html);

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String folder = 'inbox';
  List<dynamic> items = [];
  bool loading = true;
  bool failed = false;

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final result = await messages(folder);
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

  Future<void> _openMessage(Map<String, dynamic> item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MessagePage(id: item['id'] as int)),
    );
    if (changed == true && mounted) load();
  }

  Future<void> _compose() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ComposePage()),
    );
    if (sent == true && mounted) load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _folders.length,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Viestit'),
            bottom: TabBar(
              onTap: (index) {
                final nextFolder = _folders[index];
                if (nextFolder != folder) {
                  setState(() => folder = nextFolder);
                  load();
                }
              },
              tabs: [for (final label in _folderLabels) Tab(text: label)],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _compose,
            backgroundColor: KouluColors.accent,
            foregroundColor: KouluColors.background,
            tooltip: 'Uusi viesti',
            child: const Icon(Icons.edit_outlined),
          ),
          body: RefreshIndicator(
            onRefresh: load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
              children: [
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(44),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (failed)
                  RetryState(
                    message: 'Viestien lataaminen epäonnistui.',
                    onRetry: load,
                  )
                else if (items.isEmpty)
                  const EmptyState('Ei viestejä')
                else
                  for (final item in items.cast<Map<String, dynamic>>())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: KouluCard(
                        padding: EdgeInsets.zero,
                        onTap: () => _openMessage(item),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          leading: item['unread'] == true
                              ? const Icon(
                                  Icons.circle,
                                  size: 9,
                                  color: KouluColors.accent,
                                )
                              : const SizedBox(width: 9),
                          title: Text(
                            valueOf(item['subject']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: item['unread'] == true
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              valueOf(item['from']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: KouluColors.secondary,
                              ),
                            ),
                          ),
                          trailing: Text(
                            _formatTimestamp(item['timestamp']),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: KouluColors.secondary),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MessagePage extends StatefulWidget {
  final int id;

  const MessagePage({super.key, required this.id});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  Map<String, dynamic>? item;
  final replyController = TextEditingController();
  bool loading = true;
  bool failed = false;
  bool sending = false;
  bool replyFailed = false;

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final result = await message(widget.id);
      if (mounted) setState(() => item = result);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> sendReply() async {
    final body = replyController.text.trim();
    if (body.isEmpty) return;
    setState(() {
      sending = true;
      replyFailed = false;
    });
    try {
      await reply(widget.id, body);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => replyFailed = true);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowReply = item?['allow_reply'] == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          valueOf(item?['subject']).isEmpty
              ? 'Viesti'
              : valueOf(item?['subject']),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : failed
          ? RetryState(message: 'Viestin avaaminen epäonnistui.', onRetry: load)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  valueOf(item?['subject']),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  '${valueOf(item?['from'])} · ${valueOf(item?['timestamp'])}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: KouluColors.secondary),
                ),
                const SizedBox(height: 20),
                KouluCard(
                  child: SelectableText(
                    _stripHtml(valueOf(item?['html'])),
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(height: 1.55),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: !allowReply || loading || failed
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyFailed)
                      RetryState(
                        message: 'Vastauksen lähettäminen epäonnistui.',
                        onRetry: sendReply,
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: replyController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Kirjoita vastaus',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: sending ? null : sendReply,
                          tooltip: 'Lähetä vastaus',
                          icon: sending
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  List<dynamic> allRecipients = [];
  final picked = <Map<String, dynamic>>[];
  final recipientSearch = TextEditingController();
  final subjectController = TextEditingController();
  final bodyController = TextEditingController();
  bool loadingRecipients = true;
  bool recipientsFailed = false;
  bool sending = false;
  bool sendFailed = false;

  Future<void> loadRecipients() async {
    setState(() {
      loadingRecipients = true;
      recipientsFailed = false;
    });
    try {
      final result = await recipients();
      if (mounted) setState(() => allRecipients = result);
    } catch (_) {
      if (mounted) setState(() => recipientsFailed = true);
    } finally {
      if (mounted) setState(() => loadingRecipients = false);
    }
  }

  Future<void> sendMessage() async {
    if (picked.isEmpty ||
        subjectController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      sending = true;
      sendFailed = false;
    });
    try {
      await send(
        picked,
        subjectController.text.trim(),
        bodyController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => sendFailed = true);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadRecipients();
  }

  @override
  void dispose() {
    recipientSearch.dispose();
    subjectController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = recipientSearch.text.toLowerCase().trim();
    final available = allRecipients
        .cast<Map<String, dynamic>>()
        .where(
          (recipient) =>
              !picked.contains(recipient) &&
              valueOf(recipient['name']).toLowerCase().contains(query),
        )
        .take(8)
        .toList();
    final canSend =
        picked.isNotEmpty &&
        subjectController.text.trim().isNotEmpty &&
        bodyController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Sulje',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Uusi viesti'),
        actions: [
          TextButton(
            onPressed: sending || !canSend ? null : sendMessage,
            child: sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lähetä'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          TextField(
            controller: recipientSearch,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Vastaanottaja',
              hintText: 'Etsi vastaanottajaa',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          if (picked.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final recipient in picked)
                  InputChip(
                    label: Text(valueOf(recipient['name'])),
                    onDeleted: () => setState(() => picked.remove(recipient)),
                    deleteIconColor: KouluColors.secondary,
                    backgroundColor: KouluColors.navigationIndicator,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (loadingRecipients)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recipientsFailed)
            RetryState(
              message: 'Vastaanottajien lataaminen epäonnistui.',
              onRetry: loadRecipients,
            )
          else if (available.isEmpty)
            const EmptyState('Vastaanottajia ei löytynyt')
          else
            for (final recipient in available)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(valueOf(recipient['name'])),
                subtitle: valueOf(recipient['type']).isEmpty
                    ? null
                    : Text(
                        valueOf(recipient['type']),
                        style: const TextStyle(color: KouluColors.secondary),
                      ),
                trailing: const Icon(
                  Icons.add_rounded,
                  color: KouluColors.secondary,
                ),
                onTap: () => setState(() {
                  picked.add(recipient);
                  recipientSearch.clear();
                }),
              ),
          const SizedBox(height: 8),
          TextField(
            controller: subjectController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Aihe'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyController,
            onChanged: (_) => setState(() {}),
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(labelText: 'Viesti'),
          ),
          if (sendFailed)
            RetryState(
              message: 'Viestin lähettäminen epäonnistui.',
              onRetry: sendMessage,
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: sending || !canSend ? null : sendMessage,
            child: const Text('Lähetä'),
          ),
        ],
      ),
    );
  }
}
