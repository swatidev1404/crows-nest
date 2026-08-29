import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/theme_provider.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/crows_nest_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.sailing_rounded, size: 28),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Crow's Nest",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.4),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<AppThemeMode>(
            tooltip: 'Switch Theme',
            icon: Icon(
              themeProvider.currentThemeIcon,
              color: colorScheme.primary,
            ),
            onSelected: (AppThemeMode mode) {
              themeProvider.setTheme(mode);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<AppThemeMode>>[
              PopupMenuItem<AppThemeMode>(
                value: AppThemeMode.oceanicDark,
                child: Row(
                  children: [
                    const Icon(Icons.nights_stay_rounded, color: Color(0xFF38B6FF), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Midnight Oceanic',
                      style: TextStyle(
                        fontWeight: themeProvider.currentThemeMode == AppThemeMode.oceanicDark
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppThemeMode>(
                value: AppThemeMode.cyberTwilight,
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8C52FF), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Cyber Horizon',
                      style: TextStyle(
                        fontWeight: themeProvider.currentThemeMode == AppThemeMode.cyberTwilight
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppThemeMode>(
                value: AppThemeMode.nordicLight,
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: Color(0xFF0D9488), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Nordic Sea Mist',
                      style: TextStyle(
                        fontWeight: themeProvider.currentThemeMode == AppThemeMode.nordicLight
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppThemeMode>(
                value: AppThemeMode.crimsonCorsair,
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF3366), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Crimson Corsair',
                      style: TextStyle(
                        fontWeight: themeProvider.currentThemeMode == AppThemeMode.crimsonCorsair
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppThemeMode>(
                value: AppThemeMode.emeraldAbyss,
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_rounded, color: Color(0xFF00F5D4), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Emerald Abyss',
                      style: TextStyle(
                        fontWeight: themeProvider.currentThemeMode == AppThemeMode.emeraldAbyss
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<AppThemeMode>(
                value: AppThemeMode.goldenDune,
                child: Row(
                  children: [
                    const Icon(Icons.wb_twilight_rounded, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Golden Dune',
                      style: TextStyle(
                        fontWeight: themeProvider.currentThemeMode == AppThemeMode.goldenDune
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<AppThemeMode>(
                value: AppThemeMode.autoChronometer,
                child: Row(
                  children: [
                    Icon(Icons.timelapse_rounded, color: colorScheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Chronometer Shift',
                            style: TextStyle(
                              fontWeight: themeProvider.currentThemeMode == AppThemeMode.autoChronometer
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            'Auto shifts every 2 hrs',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: "Sailor's Almanac (Guide)",
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => GoRouter.of(context).go('/guide'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        width: 260,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.primary, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/crows_nest_icon.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.sailing, size: 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Crow's Nest",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              themeProvider.currentThemeName,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sailing_rounded),
              title: const Text('Voyage (Timeline)'),
              selected: _calculateSelectedIndex(context) == 0,
              onTap: () => _onItemTapped(0, context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('Calendar & History'),
              selected: _calculateSelectedIndex(context) == 1,
              onTap: () => _onItemTapped(1, context),
            ),
            ListTile(
              leading: const Icon(Icons.view_agenda_rounded),
              title: const Text('Blueprints & Routines'),
              selected: _calculateSelectedIndex(context) == 2,
              onTap: () => _onItemTapped(2, context),
            ),
            ListTile(
              leading: Icon(Icons.explore_rounded, color: colorScheme.primary),
              title: const Text(
                "Sailor's Almanac",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Captain's Guide & Lore",
                style: TextStyle(fontSize: 11),
              ),
              selected: _calculateSelectedIndex(context) == 3,
              onTap: () => _onItemTapped(3, context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme'),
              subtitle: Text(
                themeProvider.currentThemeName,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Icon(themeProvider.currentThemeIcon, size: 20),
              onTap: () {
                themeProvider.toggleNextTheme();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              selected: _calculateSelectedIndex(context) == 4,
              onTap: () => _onItemTapped(4, context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              GoRouter.of(context).go('/');
              break;
            case 1:
              GoRouter.of(context).go('/calendar');
              break;
            case 2:
              GoRouter.of(context).go('/blocks');
              break;
            case 3:
              GoRouter.of(context).go('/guide');
              break;
            case 4:
              GoRouter.of(context).go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sailing_outlined),
            selectedIcon: Icon(Icons.sailing_rounded),
            label: 'Voyage',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_agenda_outlined),
            selectedIcon: Icon(Icons.view_agenda_rounded),
            label: 'Blueprints',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Almanac',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      body: child,
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/blocks')) return 2;
    if (location.startsWith('/guide')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    Navigator.pop(context);
    
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/calendar');
        break;
      case 2:
        GoRouter.of(context).go('/blocks');
        break;
      case 3:
        GoRouter.of(context).go('/guide');
        break;
      case 4:
        GoRouter.of(context).go('/settings');
        break;
    }
  }
}
