import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/screens/app_shell.dart';
import 'package:crows_nest/screens/home_screen.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/providers/theme_provider.dart';
import 'package:crows_nest/services/sound_service.dart';
import 'package:crows_nest/screens/blueprint_manager_screen.dart';
import 'package:crows_nest/screens/settings_screen.dart';
import 'package:crows_nest/screens/calendar_screen.dart';
import 'package:crows_nest/screens/sailors_almanac_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => SoundService()),
      ],
      child: const CrowsNestApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/blocks',
          builder: (context, state) => const BlueprintManagerScreen(),
        ),
        GoRoute(
          path: '/guide',
          builder: (context, state) => const SailorsAlmanacScreen(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const Center(child: Text('Stats Screen')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class CrowsNestApp extends StatefulWidget {
  const CrowsNestApp({Key? key}) : super(key: key);

  @override
  State<CrowsNestApp> createState() => _CrowsNestAppState();
}

class _CrowsNestAppState extends State<CrowsNestApp> {
  @override
  void initState() {
    super.initState();
    // Play the young captain's crow & sea ambiance on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundService().playStartupSound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: "Crow's Nest",
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      routerConfig: _router,
    );
  }
}
