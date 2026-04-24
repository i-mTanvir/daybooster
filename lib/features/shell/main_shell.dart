import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/task_entry.dart';
import '../dashboard/dashboard_screen.dart';
import '../daily_tracker/daily_tracker_screen.dart';
import '../schedule/schedule_screen.dart';
import '../weekly_report/weekly_report_screen.dart';
import '../skills/skills_screen.dart';

class MainShell extends StatefulWidget {
  final String architectName;
  const MainShell({super.key, required this.architectName});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navController;

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
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }


  @override
  Widget build(BuildContext context) {
    final dummyTodayData = DayData(date: DateTime.now(), tasks: buildDefaultTasks());
    
    final screens = [
      DashboardScreen(architectName: widget.architectName),
      DailyTrackerScreen(todayData: dummyTodayData),
      const ScheduleScreen(),
      const WeeklyReportScreen(),
      const SkillsScreen(),
    ];

    return Scaffold(
      backgroundColor: context.themeColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: screens[_currentIndex],
        ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == i;

              return GestureDetector(
                onTap: () => _onNavTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          item.icon,
                          size: 22,
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
                          fontSize: 7,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          letterSpacing: 1,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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

