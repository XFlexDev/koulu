import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api.dart';
import 'screens/login.dart';
import 'screens/today.dart';
import 'screens/week.dart';
import 'screens/messages.dart';
import 'screens/more.dart';

void main() {
  Intl.defaultLocale = 'fi';
  runApp(const KouluApp());
}

class KouluApp extends StatelessWidget {
  const KouluApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8AB4F8),
      brightness: Brightness.dark,
    ).copyWith(surface: Colors.black, surfaceContainerHighest: const Color(0xFF141417));
    return MaterialApp(
      title: 'koulu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const Gate(),
    );
  }
}

class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  bool? authed;

  @override
  void initState() {
    super.initState();
    loadToken().then((t) => setState(() => authed = t != null));
  }

  @override
  Widget build(BuildContext context) {
    if (authed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!authed!) {
      return LoginScreen(onDone: () => setState(() => authed = true));
    }
    return Home(onLogout: () => setState(() => authed = false));
  }
}

class Home extends StatefulWidget {
  final VoidCallback onLogout;
  const Home({super.key, required this.onLogout});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TodayScreen(),
      const WeekScreen(),
      const MessagesScreen(),
      MoreScreen(onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Tänään'),
          NavigationDestination(icon: Icon(Icons.calendar_view_week_outlined), selectedIcon: Icon(Icons.calendar_view_week), label: 'Viikko'),
          NavigationDestination(icon: Icon(Icons.mail_outline), selectedIcon: Icon(Icons.mail), label: 'Viestit'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'Lisää'),
        ],
      ),
    );
  }
}
