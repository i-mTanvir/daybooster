import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/data/offline_sync_service.dart';
import '../../core/state/app_refresh_bus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';
import 'widgets/add_task_sheet.dart';

class ScheduleBlock {
  final String id;
  final String time;
  final String name;
  final String duration;
  final Color glowColor;
  final String categoryEmoji;
  final bool isFocusMode;
  final List<int> activeDays;
  final Map<String, dynamic> rawData;

  ScheduleBlock({
    required this.id,
    required this.time,
    required this.name,
    required this.duration,
    required this.glowColor,
    required this.categoryEmoji,
    required this.isFocusMode,
    required this.activeDays,
    required this.rawData,
  });
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDayIndex = 0; // 0 = Sat, 6 = Fri (matching BD/ME week start)
  List<ScheduleBlock> _allBlocks = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;

  final List<String> _days = ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI'];
  final List<String> _fullDayNames = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDirectives(showLoader: true);
    AppRefreshBus.notifier.addListener(_handleGlobalRefresh);
  }

  @override
  void dispose() {
    AppRefreshBus.notifier.removeListener(_handleGlobalRefresh);
    super.dispose();
  }

  void _handleGlobalRefresh() {
    if (!mounted) return;
    _fetchDirectives();
  }

  Future<void> _fetchDirectives({bool showLoader = false}) async {
    if (showLoader && !_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }
    try {
      final List<dynamic> data = OfflineSyncService.instance.getDirectivesLocal();
      final List<ScheduleBlock> loaded = data.map<ScheduleBlock>((dynamic rowMap) {
        final row = rowMap as Map<String, dynamic>;
        
        // Parse time (e.g. '05:30:00' -> '05:30')
        final startTimeStr = row['start_time'] as String?;
        final timeStr = (startTimeStr != null && startTimeStr.length >= 5) 
            ? startTimeStr.substring(0, 5) 
            : '00:00';
            
        final colorHexStr = row['color_hex'] as String?;
        final colorHex = (colorHexStr != null) ? colorHexStr.replaceAll('#', '') : 'FFFFFFFF';
        final colorVal = int.tryParse(colorHex, radix: 16) ?? 0xFFFFFFFF;

        return ScheduleBlock(
          id: row['id']?.toString() ?? '',
          time: timeStr,
          name: row['name'] as String? ?? 'Unknown Protocol',
          duration: '${row['duration_minutes'] ?? 0} min',
          glowColor: Color(colorVal),
          categoryEmoji: row['category_emoji'] as String? ?? '⚡',
          isFocusMode: row['is_focus_mode'] as bool? ?? false,
          activeDays: List<int>.from((row['active_days'] as List<dynamic>?) ?? []),
          rawData: row,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allBlocks = loaded;
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
      unawaited(OfflineSyncService.instance.syncNow());
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schedule: $e')),
        );
      }
    }
  }

  void _editBlock(ScheduleBlock block) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskSheet(existingDirective: block.rawData),
    ).then((_) {
      if (mounted) _fetchDirectives();
    });
  }

  Future<void> _handleDeleteDirective(ScheduleBlock block) async {
    final activeDays = List<int>.from(block.activeDays);
    final selectedDayName = _fullDayNames[_selectedDayIndex];

    if (activeDays.length <= 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.themeColors.bgCard,
          title: Text(
            'Delete Task',
            style: GoogleFonts.orbitron(
              color: context.themeColors.neonRed,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          content: Text(
            'This task is only for $selectedDayName. Delete it permanently?',
            style: GoogleFonts.shareTechMono(
              color: context.themeColors.textPrimary,
              fontSize: 12,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: TextStyle(color: context.themeColors.neonRed),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      await OfflineSyncService.instance.deleteDirective(block.id);
    } else {
      String deleteMode = 'day_only';
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            backgroundColor: context.themeColors.bgCard,
            title: Text(
              'Delete Task',
              style: GoogleFonts.orbitron(
                color: context.themeColors.neonRed,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This task is active on multiple days. Choose delete mode:',
                  style: GoogleFonts.shareTechMono(
                    color: context.themeColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                RadioGroup<String>(
                  groupValue: deleteMode,
                  onChanged: (value) => setModalState(() => deleteMode = value ?? 'day_only'),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'day_only',
                        activeColor: context.themeColors.electricBlue,
                        title: Text(
                          'Delete for $selectedDayName only',
                          style: GoogleFonts.shareTechMono(
                            color: context.themeColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        value: 'all_days',
                        activeColor: context.themeColors.neonRed,
                        title: Text(
                          'Delete for other days also',
                          style: GoogleFonts.shareTechMono(
                            color: context.themeColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: context.themeColors.neonRed),
                ),
              ),
            ],
          ),
        ),
      );

      if (confirm != true) return;

      if (deleteMode == 'all_days') {
        await OfflineSyncService.instance.deleteDirective(block.id);
      } else {
        final updatedDays = activeDays.where((d) => d != _selectedDayIndex).toList();
        if (updatedDays.isEmpty) {
          await OfflineSyncService.instance.deleteDirective(block.id);
        } else {
          await OfflineSyncService.instance.updateDirective(
            block.id,
            {'active_days': updatedDays},
          );
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Directive updated successfully',
          style: GoogleFonts.shareTechMono(color: Colors.black),
        ),
        backgroundColor: context.themeColors.neonGreen,
      ),
    );
    AppRefreshBus.bump();
    _fetchDirectives();
  }

  Future<void> _showDirectiveActions(ScheduleBlock block) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.themeColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: context.themeColors.electricBlue),
                  title: Text(
                    'Update',
                    style: GoogleFonts.orbitron(
                      color: context.themeColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'update'),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: context.themeColors.neonRed),
                  title: Text(
                    'Delete',
                    style: GoogleFonts.orbitron(
                      color: context.themeColors.neonRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'update') {
      _editBlock(block);
      return;
    }

    if (action == 'delete') {
      try {
        await _handleDeleteDirective(block);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: context.themeColors.neonRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PROTOCOL SCHEDULE',
          style: GoogleFonts.orbitron(
            color: context.themeColors.electricBlue,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(
            child: (_isLoading && !_hasLoadedOnce)
                ? Center(
                    child: CircularProgressIndicator(color: context.themeColors.electricBlue),
                  )
                : Builder(
                    builder: (context) {
                      final visibleBlocks = _allBlocks
                          .where((b) => b.activeDays.contains(_selectedDayIndex))
                          .toList()
                        ..sort((a, b) => a.time.compareTo(b.time));

                      if (visibleBlocks.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _fetchDirectives,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: [
                              const SizedBox(height: 180),
                              Center(
                                child: Text(
                                  'NO PROTOCOLS FOR THIS DAY',
                                  style: GoogleFonts.orbitron(
                                    color: context.themeColors.textMuted,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 120),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _fetchDirectives,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 100),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: visibleBlocks.length,
                          itemBuilder: (context, index) {
                            return _buildTimelineItem(visibleBlocks[index], index);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.themeColors.neonGreen.withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'schedule_fab',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddTaskSheet(),
            ).then((_) {
              if (mounted) _fetchDirectives();
            });
          },
          backgroundColor: context.themeColors.neonGreen,
          foregroundColor: Colors.black,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedDayIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
                // In future: load data specific to this day
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected ? context.themeColors.electricBlue.withValues(alpha: 0.15) : context.themeColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? context.themeColors.electricBlue : context.themeColors.borderSubtle,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  _days[index],
                  style: GoogleFonts.orbitron(
                    color: isSelected ? context.themeColors.electricBlue : context.themeColors.textMuted,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(ScheduleBlock block, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline line & dot
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Text(
                    block.time,
                    style: GoogleFonts.shareTechMono(
                      color: context.themeColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: block.glowColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Card
            Expanded(
              child: GestureDetector(
                onLongPress: () => _showDirectiveActions(block),
                child: GlowCard(
                  glowing: block.isFocusMode,
                  glowColor: block.glowColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: block.glowColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(block.categoryEmoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              block.name.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                color: context.themeColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              block.duration == '—' ? 'Event' : 'Duration: ${block.duration}',
                              style: GoogleFonts.shareTechMono(
                                color: context.themeColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 30 * index)).fadeIn().slideX(begin: 0.1),
    );
  }
}

