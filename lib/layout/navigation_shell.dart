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
import 'package:payload/core/providers/storage_providers.dart';
import 'package:payload/core/theme/app_theme.dart';

class NavigationShell extends ConsumerWidget {
  const NavigationShell({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    HistoryScreen(),
    CollectionsScreen(),
    WebSocketScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Dynamic Sidebar and Title based on selected tab
    final (title, sidebarContent) = _getNavigationData(selectedIndex);

    if (isMobile) {
      return Scaffold(
        // On mobile, the sidebar is hidden behind a drawer
        drawer: Drawer(child: sidebarContent),
        body: _buildMainContent(
          context,
          ref,
          title,
          selectedIndex,
          isMobile,
          true, // Show bottom nav on mobile
        ),
      );
    }

    // On Horizontal/Desktop view
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // Sidebar - Full height, scrollable
          sidebarContent,
          // Main content area with its own (AppBar + Body + BottomNav)
          Expanded(
            child: _buildMainContent(
              context,
              ref,
              title,
              selectedIndex,
              isMobile,
              true,
            ),
          ),
        ],
      ),
    );
  }

  /// Get the title and sidebar content for the selected index
  (String, Widget) _getNavigationData(int index) {
    switch (index) {
      case 0:
        return ('Dashboard', const RequestSidebar());
      case 1:
        return ('History', const RequestSidebar());
      case 2:
        return ('Collections', const RequestSidebar());
      case 3:
        return ('WebSocket', const SocketSidebar());
      case 4:
        return ('Settings', const RequestSidebar());
      default:
        return (Config.appName, const RequestSidebar());
    }
  }

  /// Builds the main content area with AppBar and Screen content
  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    String title,
    int selectedIndex,
    bool isMobile,
    bool showBottomNav,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          if (selectedIndex == 0) // Dashboard
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                // Add refresh logic if needed
              },
            ),
          if (selectedIndex == 1) // History
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear History',
              onPressed: () =>
                  ref.read(historyProvider.notifier).clearHistory(),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Request',
            onPressed: () => AppRouter.push(context, AppRouter.requestEditor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: showBottomNav
          ? _buildBottomNavBar(context, ref, selectedIndex)
          : null,
    );
  }

  /// Modularized Bottom Navigation Bar
  Widget _buildBottomNavBar(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 20,
        elevation: 0,
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
    );
  }
}
