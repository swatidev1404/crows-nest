import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crow's Nest"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        width: 220, // Decreased width as much as possible while looking good
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _calculateSelectedIndex(context) == 0,
              onTap: () => _onItemTapped(0, context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Calendar'),
              selected: _calculateSelectedIndex(context) == 1,
              onTap: () => _onItemTapped(1, context),
            ),
            ListTile(
              leading: const Icon(Icons.view_agenda),
              title: const Text('Blocks'),
              selected: _calculateSelectedIndex(context) == 2,
              onTap: () => _onItemTapped(2, context),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Stats'),
              selected: _calculateSelectedIndex(context) == 3,
              onTap: () => _onItemTapped(3, context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              selected: _calculateSelectedIndex(context) == 4,
              onTap: () => _onItemTapped(4, context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Static Poster placeholder
          Container(
            height: 120,
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Text(
                'Daily Poster Placeholder',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/blocks')) return 2;
    if (location.startsWith('/stats')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    // Close the drawer before navigating
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
        GoRouter.of(context).go('/stats');
        break;
      case 4:
        GoRouter.of(context).go('/settings');
        break;
    }
  }
}
