import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/data/offline_sync_service.dart';
import '../../core/services/haptics_service.dart';
import '../../core/state/app_refresh_bus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';

class DailyTrackerScreen extends StatefulWidget {
  const DailyTrackerScreen({super.key});

  @override
  State<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends State<DailyTrackerScreen> {
  // Day index: 0=Sat, 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri
  static const _dayNames = [
    'SATURDAY', 'SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'
  ];

  List<Map<String, dynamic>> _directives = [];
  // Map<directiveId, log row from daily_logs>
  final Map<String, Map<String, dynamic>> _logs = {};
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  late DateTime _today;
  late int _todayDayIndex;
  late String _todayDateStr;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _todayDayIndex = _getDayIndex(_today);
    _todayDateStr = _formatDate(_today);
    _fetchData(showLoader: true);
    _scheduleMidnightRefresh();
    AppRefreshBus.notifier.addListener(_handleGlobalRefresh);
  }

  @override
  void dispose() {
    AppRefreshBus.notifier.removeListener(_handleGlobalRefresh);
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _handleGlobalRefresh() {
    if (!mounted) return;
    _fetchData();
  }

  int _getDayIndex(DateTime date) {
    const dartToApp = {6: 0, 7: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6};
    return dartToApp[date.weekday] ?? 0;
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _scheduleMidnightRefresh() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (mounted) {
        setState(() {
          _today = DateTime.now();
          _todayDayIndex = _getDayIndex(_today);
          _todayDateStr = _formatDate(_today);
          _logs.clear();
        });
        _fetchData();
        _scheduleMidnightRefresh();
      }
    });
  }

  Future<void> _fetchData({bool showLoader = false}) async {
    if (showLoader && !_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }
    try {
      final all = OfflineSyncService.instance.getDirectivesLocal();

      // 2. Filter to today's day
      final todays = all.where((d) {
        final days = List<int>.from((d['active_days'] as List<dynamic>?) ?? []);
        return days.contains(_todayDayIndex);
      }).toList()
        ..sort((a, b) {
          final tA = (a['start_time'] as String? ?? '00:00');
          final tB = (b['start_time'] as String? ?? '00:00');
          return tA.compareTo(tB);
        });

      // 3. Fetch today's logs in one query
      final directiveIds = todays.map((d) => d['id'] as String).toList();
      final Map<String, Map<String, dynamic>> logs = {};

      if (directiveIds.isNotEmpty) {
        final allLogs = OfflineSyncService.instance.getDailyLogsLocal();
        for (final row in allLogs) {
          if (row['log_date']?.toString() != _todayDateStr) continue;
          final directiveId = row['directive_id']?.toString();
          if (directiveId == null || !directiveIds.contains(directiveId)) {
            continue;
          }
          logs[row['directive_id'] as String] = row;
        }
      }

      if (mounted) {
        setState(() {
          _directives = todays;
          _logs
            ..clear()
            ..addAll(logs);
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
      unawaited(OfflineSyncService.instance.syncNow());
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  /// UPSERT a log entry. Uses the unique constraint on (directive_id, log_date).
  Future<void> _upsertLog(String directiveId, {bool? isDone, double? progressValue}) async {
    try {
      final res = await OfflineSyncService.instance.upsertDailyLog(
        directiveId: directiveId,
        logDate: _todayDateStr,
        isDone: isDone,
        progressValue: progressValue,
      );

      if (mounted) {
        setState(() => _logs[directiveId] = res);
      }
      unawaited(OfflineSyncService.instance.syncNow());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: context.themeColors.neonRed),
        );
      }
    }
  }

  Future<void> _setBinarySelection(String directiveId, bool? state) async {
    try {
      final res = await OfflineSyncService.instance.setDailyLogBinaryState(
        directiveId: directiveId,
        logDate: _todayDateStr,
        isDone: state,
      );
      if (!mounted) return;
      setState(() => _logs[directiveId] = res);
      unawaited(OfflineSyncService.instance.syncNow());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: context.themeColors.neonRed,
        ),
      );
    }
  }

  Future<void> _showBinaryLongPressMenu(Map<String, dynamic> directive) async {
    final directiveId = directive['id'] as String?;
    if (directiveId == null) return;

    final current = _logs[directiveId]?['is_done'] as bool?;
    final title = (directive['name'] as String? ?? 'Task').toUpperCase();

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.themeColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (context) {
        final colors = context.themeColors;
        final items = <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.orbitron(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ];

        if (current == null) {
          items.addAll([
            ListTile(
              leading: Icon(Icons.check_circle_outline, color: colors.neonGreen),
              title: Text('Mark Done', style: GoogleFonts.shareTechMono(color: colors.textPrimary)),
              onTap: () => Navigator.pop(context, 'done'),
            ),
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: colors.neonRed),
              title: Text('Mark Missed', style: GoogleFonts.shareTechMono(color: colors.textPrimary)),
              onTap: () => Navigator.pop(context, 'missed'),
            ),
          ]);
        } else {
          items.add(
            ListTile(
              leading: Icon(Icons.remove_circle_outline, color: colors.gold),
              title: Text('Remove Selection', style: GoogleFonts.shareTechMono(color: colors.textPrimary)),
              onTap: () => Navigator.pop(context, 'clear'),
            ),
          );
        }

        items.add(
          ListTile(
            leading: Icon(Icons.close, color: colors.textMuted),
            title: Text('Cancel', style: GoogleFonts.shareTechMono(color: colors.textMuted)),
            onTap: () => Navigator.pop(context, 'cancel'),
          ),
        );

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items,
          ),
        );
      },
    );

    if (!mounted || action == null || action == 'cancel') return;
    HapticsService.selectionClick();
    if (action == 'done') {
      await _setBinarySelection(directiveId, true);
      unawaited(_showDoneCelebration(directive['name'] as String? ?? 'Task'));
    } else if (action == 'missed') {
      await _setBinarySelection(directiveId, false);
    } else if (action == 'clear') {
      await _setBinarySelection(directiveId, null);
    }
  }

  Future<void> _showDoneCelebration(String title) async {
    if (!mounted) return;
    var dialogOpen = true;
    unawaited(
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (!mounted || !dialogOpen) return;
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
        }
      }),
    );

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Celebration',
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, __) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.themeColors.bgCardLight,
                context.themeColors.bgCard,
              ],
            ),
            border: Border.all(
              color: context.themeColors.neonGreen.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: context.themeColors.neonGreen.withValues(alpha: 0.25),
                blurRadius: 22,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.themeColors.neonGreen.withValues(alpha: 0.14),
                ),
                child: Icon(
                  Icons.celebration_rounded,
                  color: context.themeColors.neonGreen,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'TASK COMPLETED',
                style: GoogleFonts.orbitron(
                  color: context.themeColors.neonGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 110,
                height: 2,
                color: context.themeColors.neonGreen.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 10),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.shareTechMono(
                  color: context.themeColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
      transitionBuilder: (context, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
    dialogOpen = false;
  }

  String _formatTime(String? rawTime) {
    if (rawTime == null || rawTime.length < 5) return '--:--';
    return rawTime.substring(0, 5);
  }

  bool _isCompletedForOrdering(Map<String, dynamic> directive) {
    final directiveId = directive['id'] as String?;
    if (directiveId == null) return false;

    final trackingType = directive['tracking_type'] as String? ?? 'binary';
    final log = _logs[directiveId];
    if (log == null) return false;

    // For this UX rule, only binary directives move down after DONE/MISSED.
    if (trackingType == 'binary') {
      return log['is_done'] != null;
    }

    return false;
  }

  List<Map<String, dynamic>> _orderedDirectives() {
    final ordered = List<Map<String, dynamic>>.from(_directives);
    ordered.sort((a, b) {
      final aDone = _isCompletedForOrdering(a);
      final bDone = _isCompletedForOrdering(b);
      if (aDone != bDone) {
        return aDone ? 1 : -1; // incomplete first, completed last
      }
      final tA = (a['start_time'] as String? ?? '00:00');
      final tB = (b['start_time'] as String? ?? '00:00');
      return tA.compareTo(tB);
    });
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final dayName = _dayNames[_todayDayIndex];
    final orderedDirectives = _orderedDirectives();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DAILY TRACKER',
              style: GoogleFonts.orbitron(
                color: colors.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            Text(
              dayName,
              style: GoogleFonts.shareTechMono(
                color: colors.textMuted,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      body: (_isLoading && !_hasLoadedOnce)
          ? Center(child: CircularProgressIndicator(color: colors.neonGreen))
          : _directives.isEmpty
              ? RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      const SizedBox(height: 120),
                      _buildEmptyState(colors, dayName),
                      const SizedBox(height: 120),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSummaryBar(colors),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20).copyWith(bottom: 100),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: orderedDirectives.length,
                          itemBuilder: (context, index) {
                            final directive = orderedDirectives[index];
                            final directiveId = directive['id'] as String;
                            final log = _logs[directiveId];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildDirectiveCard(directive, log, colors, index),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  ({int total, int done, int missed, int progress, int pending}) _computeSummary() {
    int done = 0, missed = 0, progress = 0;
    for (final directive in _directives) {
      final id = directive['id'] as String;
      final log = _logs[id];
      final trackingType = directive['tracking_type'] as String? ?? 'binary';
      if (log == null) continue;
      if (trackingType == 'binary') {
        final isDone = log['is_done'] as bool?;
        if (isDone == true) { done++; }
        else if (isDone == false) { missed++; }
      } else {
        final val = (log['progress_value'] as num?)?.toDouble() ?? 0.0;
        if (val > 0) { progress++; }
      }
    }
    final logged = done + missed + progress;
    final pending = _directives.length - logged;
    return (total: _directives.length, done: done, missed: missed, progress: progress, pending: pending);
  }

  Widget _buildSummaryBar(AppThemeColors colors) {
    final s = _computeSummary();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryChip('TOTAL', '${s.total}', colors.textPrimary, colors),
          _summaryDivider(colors),
          _summaryChip('DONE', '${s.done}', colors.neonGreen, colors),
          _summaryDivider(colors),
          _summaryChip('MISSED', '${s.missed}', colors.neonRed, colors),
          _summaryDivider(colors),
          _summaryChip('PROGRESS', '${s.progress}', colors.electricBlue, colors),
          _summaryDivider(colors),
          _summaryChip('PENDING', '${s.pending}', colors.textMuted, colors),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color, AppThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: color.withValues(alpha: 0.7),
            fontSize: 8,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _summaryDivider(AppThemeColors colors) {
    return Container(
      width: 1,
      height: 32,
      color: colors.borderSubtle,
    );
  }

  Widget _buildEmptyState(AppThemeColors colors, String dayName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'NO PROTOCOLS FOR $dayName',
            style: GoogleFonts.orbitron(color: colors.textMuted, fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Add tasks in the Schedule screen\nand assign them to this day.',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              color: colors.textMuted.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectiveCard(
    Map<String, dynamic> directive,
    Map<String, dynamic>? log,
    AppThemeColors colors,
    int index,
  ) {
    final directiveId = directive['id'] as String;
    final name = directive['name'] as String? ?? 'Unknown';
    final emoji = directive['category_emoji'] as String? ?? '⚡';
    final timeStr = _formatTime(directive['start_time'] as String?);
    final durationMin = directive['duration_minutes'] as int? ?? 0;
    final trackingType = directive['tracking_type'] as String? ?? 'binary';
    final isFocus = directive['is_focus_mode'] as bool? ?? false;
    final colorHexStr = (directive['color_hex'] as String? ?? 'FF00F0FF').replaceAll('#', '');
    final colorVal = int.tryParse(colorHexStr, radix: 16) ?? 0xFF00F0FF;
    final glowColor = Color(colorVal);

    // Derive logged state
    final isDone = log?['is_done'] as bool?;
    final progressValue = (log?['progress_value'] as num?)?.toDouble() ?? 0.0;
    final hasLog = log != null;

    return GestureDetector(
      onLongPress: trackingType == 'binary'
          ? () => _showBinaryLongPressMenu(directive)
          : null,
      child: GlowCard(
        glowing: isFocus || (hasLog && isDone == true),
        glowColor: hasLog && isDone == true ? colors.neonGreen : glowColor,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$timeStr  •  ${durationMin > 0 ? '$durationMin min' : 'Event'}',
                      style: GoogleFonts.shareTechMono(color: colors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Status badge
              if (hasLog) ...[
                if (trackingType == 'binary')
                  _statusBadge(isDone == true ? 'DONE' : 'MISSED',
                      isDone == true ? colors.neonGreen : colors.neonRed)
                else
                  _statusBadge(
                    '${progressValue.toInt()}/${directive['target_metric'] ?? '?'}',
                    colors.electricBlue,
                  ),
              ],
              if (isFocus && !hasLog) ...[
                const SizedBox(width: 6),
                _statusBadge('FOCUS', colors.gold),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (trackingType == 'binary')
            _buildBinaryToggle(directiveId, isDone, colors)
          else
            _buildProgressSlider(directive, log, colors),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.05);
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.orbitron(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildBinaryToggle(String directiveId, bool? isDone, AppThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: _buildBinaryButton(
            title: 'MISSED',
            isSelected: isDone == false,
            color: colors.neonRed,
            onTap: () {
              HapticsService.lightImpact();
              _upsertLog(directiveId, isDone: false);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBinaryButton(
            title: 'DONE',
            isSelected: isDone == true,
            color: colors.neonGreen,
            onTap: () {
              HapticsService.lightImpact();
              _upsertLog(directiveId, isDone: true);
              if (isDone != true) {
                unawaited(_showDoneCelebration(
                  _directives.firstWhere(
                    (d) => d['id'] == directiveId,
                    orElse: () => {'name': 'Task'},
                  )['name'] as String? ?? 'Task',
                ));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSlider(
    Map<String, dynamic> directive,
    Map<String, dynamic>? log,
    AppThemeColors colors,
  ) {
    final directiveId = directive['id'] as String;
    final target = (directive['target_metric'] as num?)?.toDouble() ?? 60;
    final metricName = directive['metric_name'] as String? ?? 'Minutes';
    final current = (log?['progress_value'] as num?)?.toDouble() ?? 0.0;
    final maxVal = (target * 1.5).roundToDouble();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LOG $metricName:'.toUpperCase(),
              style: GoogleFonts.shareTechMono(color: colors.textSecondary, fontSize: 10),
            ),
            Text(
              '${current.toInt()} / ${target.toInt()}',
              style: GoogleFonts.shareTechMono(
                color: colors.electricBlue,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: colors.electricBlue,
            inactiveTrackColor: colors.bgCardLight,
            thumbColor: colors.electricBlue,
            overlayColor: colors.electricBlue.withValues(alpha: 0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: current.clamp(0, maxVal),
            min: 0,
            max: maxVal,
            divisions: maxVal.toInt(),
            onChanged: (val) {
              HapticsService.selectionClick();
              // Optimistic local update
              setState(() {
                _logs[directiveId] = {
                  ...(_logs[directiveId] ?? {}),
                  'progress_value': val,
                };
              });
            },
            onChangeEnd: (val) {
              // Persist to DB only when user releases the thumb
              _upsertLog(directiveId, progressValue: val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBinaryButton({
    required String title,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : context.themeColors.bgCardLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : context.themeColors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.orbitron(
              color: isSelected ? color : context.themeColors.textMuted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
