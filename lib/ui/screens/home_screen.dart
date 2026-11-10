import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/incident_enums.dart';
import '../../state/auth_providers.dart';
import '../../state/incident_providers.dart';
import 'feed_screen.dart';
import 'home_tab.dart';
import 'my_reports_tab.dart';
import 'staff_home_tab.dart';
import 'report_form_screen.dart';
import 'staff_dashboard_screen.dart';

/// Main shell with the bottom navigation bar and the round "Report" button.
/// Tabs: Home, Reports, Dashboard (staff only) and Profile.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _home = 0, _reports = 1, _dashboard = 2, _profile = 3;
  int _tab = _home;

  void _openReports({IncidentStatus? status, bool mineOnly = false}) {
    final filter = ref.read(incidentFilterProvider.notifier);
    filter.reset();
    if (status != null) filter.setStatus(status);
    if (mineOnly) filter.setMineOnly(true);
    setState(() => _tab = _reports);
  }

  void _openForm() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReportFormScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(isStaffProvider);
    final tab = (!isStaff && _tab == _dashboard) ? _home : _tab;

    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          // Staff get a portal with every report on campus;
          // students see a summary of their own reports.
          isStaff
              ? StaffHomeTab(
                  onOpenStatus: (s) => _openReports(status: s),
                  onOpenAll: () => _openReports(),
                  onOpenProfile: () => setState(() => _tab = _profile),
                )
              : HomeTab(
                  onReport: _openForm,
                  onSeeAll: () => _openReports(mineOnly: true),
                  onOpenProfile: () => setState(() => _tab = _profile),
                ),
          _TabPage(title: isStaff ? 'All reports' : 'Reports', child: const FeedScreen()),
          isStaff
              ? _TabPage(
                  title: 'Staff dashboard',
                  child: StaffDashboardScreen(
                    onStatusSelected: (s) => _openReports(status: s),
                  ),
                )
              : const SizedBox.shrink(),
          const MyReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        tooltip: 'Report an issue',
        shape: const CircleBorder(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 72,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              selected: tab == _home,
              onTap: () => setState(() => _tab = _home),
            ),
            _NavItem(
              icon: Icons.description_outlined,
              selectedIcon: Icons.description,
              label: 'Reports',
              selected: tab == _reports,
              onTap: () => setState(() => _tab = _reports),
            ),
            const Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Report', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
              ),
            ),
            if (isStaff)
              _NavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard,
                label: 'Dashboard',
                selected: tab == _dashboard,
                onTap: () => setState(() => _tab = _dashboard),
              ),
            _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              selected: tab == _profile,
              onTap: () => setState(() => _tab = _profile),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tab with a simple bold title at the top.
class _TabPage extends StatelessWidget {
  const _TabPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
