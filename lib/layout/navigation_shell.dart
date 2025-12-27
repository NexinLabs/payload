import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payload/features/dashboard/dashboard_screen.dart';
import 'package:payload/features/history/history_screen.dart';
import 'package:payload/features/collections/collections_screen.dart';
import 'package:payload/features/settings/settings_screen.dart';
import 'package:payload/core/router/app_router.dart';
import 'package:payload/features/request/components/request_sidebar.dart';
import 'package:payload/core/providers/navigation_provider.dart';

class NavigationShell extends ConsumerWidget {
  const NavigationShell({super.key});

  final List<Widget> _screens = const [
    DashboardScreen(),
    HistoryScreen(),
    CollectionsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/app_logo.png', height: 24),
            const SizedBox(width: 10),
            const Text('PAYLOAD'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              AppRouter.push(context, AppRouter.requestEditor);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const RequestSidebar(),
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
