import 'package:flutter/material.dart';
import '../api.dart';

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
  String? error;

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await login(url.text.trim(), user.text.trim(), pass.text);
      widget.onDone();
    } on ApiException catch (e) {
      setState(() => error = e.message);
    } catch (_) {
      setState(() => error = 'Yhteys epäonnistui');
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
                Text('koulu',
                    style: t.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Wilma, mutta toimii.',
                    style: t.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                TextField(
                  controller: url,
                  decoration: const InputDecoration(
                    labelText: 'Wilma-osoite',
                    hintText: 'https://koulu.inschool.fi',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: user,
                  decoration: const InputDecoration(
                    labelText: 'Käyttäjätunnus',
                    border: OutlineInputBorder(),
                  ),
                  autocorrect: false,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pass,
                  decoration: const InputDecoration(
                    labelText: 'Salasana',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  autocorrect: false,
                  onSubmitted: (_) => submit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : submit,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
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
