import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/data/offline_sync_service.dart';
import '../../core/services/haptics_service.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../daily_tracker/daily_tracker_screen.dart';
import '../schedule/schedule_screen.dart';
import '../weekly_report/weekly_report_screen.dart';
import '../skills/skills_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navController;
  late PageController _pageController;
  String _architectName = 'Architect';
  late List<Widget> _screens;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.grid_view_rounded, label: 'DASHBOARD'),
    _NavItem(icon: Icons.check_circle_outline_rounded, label: 'DAILY'),
    _NavItem(icon: Icons.calendar_month_rounded, label: 'SCHEDULE'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'WEEKLY'),
    _NavItem(icon: Icons.psychology_rounded, label: 'SKILLS'),
  ];

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      _KeepAlivePage(child: DashboardScreen(architectName: _architectName)),
      const _KeepAlivePage(child: DailyTrackerScreen()),
      const _KeepAlivePage(child: ScheduleScreen()),
      const _KeepAlivePage(child: WeeklyReportScreen()),
      const _KeepAlivePage(child: SkillsScreen()),
    ];
    _loadArchitectName();
  }

  @override
  void dispose() {
    _navController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    HapticsService.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadArchitectName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profile = OfflineSyncService.instance.getProfileLocal();
      unawaited(OfflineSyncService.instance.syncNow());

      final profileName = profile?['architect_name'] as String?;
      final metadataName = user.userMetadata?['name'] as String?;
      final resolvedName = (profileName?.trim().isNotEmpty ?? false)
          ? profileName!.trim()
          : ((metadataName?.trim().isNotEmpty ?? false) ? metadataName!.trim() : 'Architect');

      if (mounted) {
        setState(() {
          _architectName = resolvedName;
          _screens[0] = _KeepAlivePage(
            child: DashboardScreen(architectName: _architectName),
          );
        });
      }
    } catch (_) {
      final user = Supabase.instance.client.auth.currentUser;
      final fallback = user?.userMetadata?['name'] as String?;
      if (mounted && fallback != null && fallback.trim().isNotEmpty) {
        setState(() {
          _architectName = fallback.trim();
          _screens[0] = _KeepAlivePage(
            child: DashboardScreen(architectName: _architectName),
          );
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeColors.bg,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (_currentIndex != index) {
            HapticsService.selectionClick();
            setState(() => _currentIndex = index);
          }
        },
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.bgCard,
        border: Border(
          top: BorderSide(color: context.themeColors.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: context.themeColors.electricBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 410;
            final horizontalPadding = isCompact ? 4.0 : 8.0;
            final itemHorizontalPadding = isCompact ? 6.0 : 12.0;
            final iconSize = isCompact ? 20.0 : 22.0;
            final labelSize = isCompact ? 6.5 : 7.0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
              child: Row(
                children: _navItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isSelected = _currentIndex == i;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onNavTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: EdgeInsets.symmetric(horizontal: itemHorizontalPadding, vertical: 8),
                        decoration: isSelected
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: context.themeColors.electricBlue.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: context.themeColors.electricBlue.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.themeColors.electricBlue.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                  ),
                                ],
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                item.icon,
                                size: iconSize,
                                color: isSelected
                                    ? context.themeColors.electricBlue
                                    : context.themeColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: GoogleFonts.orbitron(
                                color: isSelected
                                    ? context.themeColors.electricBlue
                                    : context.themeColors.textMuted,
                                fontSize: labelSize,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                letterSpacing: 1,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(item.label, maxLines: 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

