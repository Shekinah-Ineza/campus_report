import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/incident_enums.dart';
import '../../state/auth_providers.dart';
import '../../state/incident_providers.dart';
import 'feed_screen.dart';
import 'report_form_screen.dart';
import 'staff_dashboard_screen.dart';

/// Main shell. Students see the reports list; staff also get a dashboard tab.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  void _openFeedWithStatus(IncidentStatus status) {
    final filter = ref.read(incidentFilterProvider.notifier);
    filter.reset();
    filter.setStatus(status);
    setState(() => _tab = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(isStaffProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final tab = isStaff ? _tab : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(tab == 0 ? 'Campus reports' : 'Staff dashboard'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: CircleAvatar(
              radius: 16,
              child: Text(
                (profile?.name.isNotEmpty ?? false) ? profile!.name[0].toUpperCase() : '?',
              ),
            ),
            onSelected: (value) {
              if (value == 'signout') ref.read(authControllerProvider.notifier).signOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(profile?.name ?? ''),
                  subtitle: Text('${profile?.email ?? ''}\n${isStaff ? 'Staff' : 'Student'} account'),
                  isThreeLine: true,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: [
          const FeedScreen(),
          if (isStaff) StaffDashboardScreen(onStatusSelected: _openFeedWithStatus),
        ],
      ),
      floatingActionButton: tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportFormScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Report a problem'),
            )
          : null,
      bottomNavigationBar: isStaff
          ? NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
              ],
            )
          : null,
    );
  }
}
