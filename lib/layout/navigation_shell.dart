import 'package:flutter/material.dart';
import 'package:payload/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payload/features/dashboard/dashboard_screen.dart';
import 'package:payload/features/history/history_screen.dart';
import 'package:payload/features/collections/collections_screen.dart';
import 'package:payload/features/settings/settings_screen.dart';
import 'package:payload/features/socket/socket_screen.dart';
import 'package:payload/features/socket/components/socket_sidebar.dart';
import 'package:payload/core/router/app_router.dart';
import 'package:payload/features/request/components/request_sidebar.dart';
import 'package:payload/core/providers/navigation_provider.dart';

class NavigationShell extends ConsumerWidget {
  const NavigationShell({super.key});

  final List<Widget> _screens = const [
    DashboardScreen(),
    HistoryScreen(),
    CollectionsScreen(),
    WebSocketScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    // Dynamic Sidebar and Title based on selected tab
    Widget sidebarContent;
    String title;
    switch (selectedIndex) {
      case 0:
        title = 'Dashboard';
        sidebarContent = const RequestSidebar();
        break;
      case 1:
        title = 'History';
        sidebarContent = const RequestSidebar();
        break;
      case 2:
        title = 'Collections';
        sidebarContent = const RequestSidebar();
        break;
      case 3:
        title = 'WebSocket';
        sidebarContent = const SocketSidebar();
        break;
      case 4:
        title = 'Settings';
        sidebarContent = const RequestSidebar();
        break;
      default:
        title = Config.appName;
        sidebarContent = const RequestSidebar();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/app_logo.png', height: 24),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
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
      drawer: isMobile ? sidebarContent : null,
      body: Row(
        children: [
          if (!isMobile) sidebarContent,
          Expanded(
            child: IndexedStack(index: selectedIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
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
              icon: Icon(Icons.electrical_services_outlined),
              activeIcon: Icon(Icons.electrical_services),
              label: 'Socket',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
