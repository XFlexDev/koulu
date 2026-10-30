import 'package:flutter/material.dart';

import '../api.dart';
import '../ui.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onDone;
  const LoginScreen({super.key, required this.onDone});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final url = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();
  bool busy = false;
  bool failed = false;

  Future<void> submit() async {
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      await login(url.text.trim(), user.text.trim(), pass.text);
      widget.onDone();
    } on ApiException {
      setState(() => failed = true);
    } catch (_) {
      setState(() => failed = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    url.dispose();
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'koulu',
                  style: t.displaySmall?.copyWith(
                    color: KouluColors.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Wilman tärkeimmät asiat, selkeästi.',
                  style: t.bodyMedium?.copyWith(color: KouluColors.secondary),
                ),
                const SizedBox(height: 34),
                TextField(
                  controller: url,
                  decoration: const InputDecoration(
                    labelText: 'Wilma-osoite',
                    hintText: 'https://savonlinna.inschool.fi',
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: user,
                  decoration: const InputDecoration(
                    labelText: 'Käyttäjätunnus',
                  ),
                  autocorrect: false,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pass,
                  decoration: const InputDecoration(labelText: 'Salasana'),
                  obscureText: true,
                  autocorrect: false,
                  onSubmitted: (_) => submit(),
                ),
                if (failed) ...[
                  const SizedBox(height: 12),
                  RetryState(
                    message: 'Kirjautuminen epäonnistui. Tarkista osoite ja tunnukset.',
                    onRetry: submit,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kirjaudu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
