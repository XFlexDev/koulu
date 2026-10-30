import 'package:flutter/material.dart';

import 'api.dart';
import 'ui.dart';
import 'screens/announcements.dart';
import 'screens/login.dart';
import 'screens/today.dart';
import 'screens/week.dart';
import 'screens/messages.dart';
import 'screens/more.dart';

void main() {
  runApp(const KouluApp());
}

class KouluApp extends StatelessWidget {
  const KouluApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'koulu',
      debugShowCheckedModeBanner: false,
      theme: kouluTheme(),
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
      HomeScreen(onNavigate: (i) => setState(() => index = i)),
      const MessagesScreen(),
      const NewsScreen(),
      const WeekScreen(),
      MoreScreen(onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Koti',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline_rounded),
            selectedIcon: Icon(Icons.mail_rounded),
            label: 'Viestit',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Tiedotteet',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lukkari',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'Lisää',
          ),
        ],
      ),
    );
  }
}
