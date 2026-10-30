import 'package:flutter/material.dart';

class KouluColors {
  static const background = Color(0xFF000000);
  static const header = Color(0xFF0E2318);
  static const card = Color(0xFF07120C);
  static const border = Color(0xFF18301F);
  static const accent = Color(0xFF3DDC84);
  static const secondary = Color(0xFF8FA597);
  static const text = Color(0xFFE8F0EA);
  static const navigationIndicator = Color(0xFF1B4A2E);
}

ThemeData kouluTheme() {
  const scheme = ColorScheme.dark(
    primary: KouluColors.accent,
    onPrimary: KouluColors.background,
    secondary: KouluColors.accent,
    onSecondary: KouluColors.background,
    surface: KouluColors.background,
    onSurface: KouluColors.text,
    surfaceContainerHighest: KouluColors.card,
    onSurfaceVariant: KouluColors.secondary,
    outline: KouluColors.border,
    error: Color(0xFFFF8A80),
    onError: KouluColors.background,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: KouluColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: KouluColors.background,
      foregroundColor: KouluColors.text,
      surfaceTintColor: KouluColors.background,
      titleTextStyle: TextStyle(
        color: KouluColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: KouluColors.header,
      indicatorColor: KouluColors.navigationIndicator,
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: KouluColors.accent,
      unselectedLabelColor: KouluColors.secondary,
      indicatorColor: KouluColors.accent,
      dividerColor: KouluColors.border,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KouluColors.card,
      labelStyle: const TextStyle(color: KouluColors.secondary),
      hintStyle: const TextStyle(color: KouluColors.secondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KouluColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KouluColors.accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF8A80)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.4),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: KouluColors.accent,
    ),
    dividerTheme: const DividerThemeData(
      color: KouluColors.border,
      thickness: 1,
      space: 1,
    ),
  );
}

class KouluCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const KouluCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Container(
      decoration: BoxDecoration(
        color: KouluColors.card,
        border: Border.all(color: KouluColors.border),
        borderRadius: radius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const SectionHeading(this.title, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: KouluColors.secondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: onTap == null
          ? label
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: label),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: KouluColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class RetryState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const RetryState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 30,
            color: KouluColors.secondary,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: const Text('Yritä uudelleen')),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;

  const EmptyState(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: KouluColors.secondary),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final Map<String, String> headers;

  const ProfileAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return ClipOval(
      child: SizedBox.square(
        dimension: 72,
        child: Image.network(
          imageUrl,
          headers: headers,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _fallback(initials.isEmpty ? 'K' : initials),
        ),
      ),
    );
  }

  Widget _fallback(String initials) => Container(
    color: KouluColors.navigationIndicator,
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        color: KouluColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String valueOf(dynamic value) => value?.toString() ?? '';

String stripHtml(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</(p|div|li)>', caseSensitive: false), '\n\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .trim();

String cardDate(dynamic value) {
  final text = valueOf(value);
  final date = DateTime.tryParse(text);
  if (date != null) {
    return '${date.day}.${date.month}.';
  }
  return text;
}
