import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/data/offline_sync_service.dart';
import '../../core/state/app_refresh_bus.dart';
import '../../core/models/vibe_character.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String? _loadError;

  double _weeklyAverage = 0;
  List<Map<String, dynamic>> _days = [];
  List<Map<String, dynamic>> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadWeeklyData(showLoader: true);
    AppRefreshBus.notifier.addListener(_handleGlobalRefresh);
  }

  @override
  void dispose() {
    AppRefreshBus.notifier.removeListener(_handleGlobalRefresh);
    super.dispose();
  }

  void _handleGlobalRefresh() {
    if (!mounted) return;
    _loadWeeklyData();
  }

  int _getDayIndex(DateTime date) {
    const dartToApp = {6: 0, 7: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6};
    return dartToApp[date.weekday] ?? 0;
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool _looksLikePrayer(Map<String, dynamic> directive) {
    final name = (directive['name'] as String? ?? '').toLowerCase();
    final emoji = (directive['category_emoji'] as String? ?? '').trim();
    const prayerKeywords = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'prayer', 'namaz'];
    return emoji == '\u{1F54C}' || prayerKeywords.any(name.contains);
  }

  bool _looksLikeWorkout(Map<String, dynamic> directive) {
    final name = (directive['name'] as String? ?? '').toLowerCase();
    final emoji = (directive['category_emoji'] as String? ?? '').trim();
    const workoutKeywords = ['workout', 'gym', 'exercise', 'training'];
    return emoji == '\u{1F3CB}\u{FE0F}' || workoutKeywords.any(name.contains);
  }

  bool _looksLikeSleep(Map<String, dynamic> directive) {
    final name = (directive['name'] as String? ?? '').toLowerCase();
    final emoji = (directive['category_emoji'] as String? ?? '').trim();
    return emoji == '\u{1F634}' || name.contains('sleep');
  }

  double _percentageForDirective(Map<String, dynamic> directive, Map<String, dynamic>? log) {
    final trackingType = (directive['tracking_type'] as String? ?? 'binary').toLowerCase();
    switch (trackingType) {
      case 'progress':
        final target = ((directive['target_metric'] as num?)?.toDouble() ??
                (directive['duration_minutes'] as int?)?.toDouble() ??
                60)
            .clamp(1, 1000000);
        final actual = (log?['progress_value'] as num?)?.toDouble() ?? 0;
        return ((actual / target) * 100).clamp(0, 200);
      case 'inverse':
        final used = (log?['progress_value'] as num?)?.toDouble() ?? 0;
        return (((60 - used) / 60) * 100).clamp(0, 100);
      case 'binary':
      default:
        return (log?['is_done'] as bool?) == true ? 100 : 0;
    }
  }

  Future<void> _loadWeeklyData({bool showLoader = false}) async {
    if (!mounted) return;
    if (showLoader && !_hasLoadedOnce) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    } else {
      _loadError = null;
    }

    try {
      

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: _getDayIndex(today)));
      final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
      final rangeStart = _formatDate(weekDays.first);
      final rangeEnd = _formatDate(weekDays.last);

      final directives = OfflineSyncService.instance.getDirectivesLocal();

      final directiveIds = directives
          .map((d) => d['id']?.toString())
          .whereType<String>()
          .toList();

      final Map<String, Map<String, Map<String, dynamic>>> logsByDateDirective = {};
      if (directiveIds.isNotEmpty) {
        final localLogs = OfflineSyncService.instance.getDailyLogsLocal();
        for (final row in localLogs) {
          final dateKey = row['log_date']?.toString();
          final directiveId = row['directive_id']?.toString();
          if (dateKey == null || directiveId == null) continue;
          if (!directiveIds.contains(directiveId)) continue;
          if (dateKey.compareTo(rangeStart) < 0 || dateKey.compareTo(rangeEnd) > 0) continue;
          logsByDateDirective.putIfAbsent(dateKey, () => {});
          logsByDateDirective[dateKey]![directiveId] = row;
        }
      }

      final summaryByDate = <String, double>{};

      final builtDays = <Map<String, dynamic>>[];
      final workoutDoneDays = <String>{};
      final sleepDoneDays = <String>{};
      int prayerDoneTotal = 0;
      int prayerTaskTotal = 0;
      int focusCompletedCount = 0;

      for (final day in weekDays) {
        final dayIndex = _getDayIndex(day);
        final dateKey = _formatDate(day);

        final dayDirectives = directives.where((directive) {
          final activeDays = List<int>.from((directive['active_days'] as List<dynamic>?) ?? []);
          return activeDays.contains(dayIndex);
        }).toList();

        int doneCount = 0;
        int missedCount = 0;
        int progressLoggedCount = 0;
        int prayerDoneForDay = 0;
        int prayerTotalForDay = 0;
        double dayScore = 0;

        if (dayDirectives.isNotEmpty) {
          double total = 0;
          for (final directive in dayDirectives) {
            final id = directive['id']?.toString();
            if (id == null) continue;

            final log = logsByDateDirective[dateKey]?[id];
            final pct = _percentageForDirective(directive, log);
            total += pct;

            if (pct >= 100) {
              doneCount++;
            }

            final trackingType = (directive['tracking_type'] as String? ?? 'binary').toLowerCase();
            if (trackingType == 'binary' && (log?['is_done'] as bool?) == false) {
              missedCount++;
            }
            if (trackingType != 'binary' && ((log?['progress_value'] as num?)?.toDouble() ?? 0) > 0) {
              progressLoggedCount++;
            }

            final isDone = pct >= 100;
            if (_looksLikePrayer(directive)) {
              prayerTaskTotal++;
              prayerTotalForDay++;
              if ((log?['is_done'] as bool?) == true) {
                prayerDoneTotal++;
                prayerDoneForDay++;
              }
            }

            if (_looksLikeWorkout(directive) && isDone) {
              workoutDoneDays.add(dateKey);
            }

            if (_looksLikeSleep(directive) && isDone) {
              sleepDoneDays.add(dateKey);
            }

            if ((directive['is_focus_mode'] as bool? ?? false) && isDone) {
              focusCompletedCount++;
            }
          }

          dayScore = total / dayDirectives.length;
        } else {
          dayScore = summaryByDate[dateKey] ?? 0;
        }

        builtDays.add({
          'day': DateFormat('EEEE').format(day),
          'date': DateFormat('d MMM').format(day),
          'score': dayScore,
          'total': dayDirectives.length,
          'done': doneCount,
          'missed': missedCount,
          'progress': progressLoggedCount,
          'prayer': '$prayerDoneForDay/$prayerTotalForDay',
        });
      }

      final weeklyAverage = builtDays.isEmpty
          ? 0.0
          : builtDays.fold<double>(0, (sum, d) => sum + (d['score'] as double)) / builtDays.length;

      int currentStreak = 0;
      int bestStreak = 0;
      for (final day in builtDays) {
        final score = day['score'] as double;
        if (score >= 90) {
          currentStreak++;
          if (currentStreak > bestStreak) bestStreak = currentStreak;
        } else {
          currentStreak = 0;
        }
      }

      final badges = [
        {
          'iconData': Icons.local_fire_department_rounded,
          'name': '5-Day Streak',
          'earned': bestStreak >= 5,
        },
        {
          'iconData': Icons.mosque_rounded,
          'name': 'Prayer Warrior',
          'earned': prayerTaskTotal > 0 && prayerDoneTotal == prayerTaskTotal,
        },
        {
          'iconData': Icons.fitness_center_rounded,
          'name': 'Iron Body',
          'earned': workoutDoneDays.length >= 4,
        },
        {
          'iconData': Icons.psychology_alt_rounded,
          'name': 'Deep Focus',
          'earned': focusCompletedCount >= 4,
        },
        {
          'iconData': Icons.workspace_premium_rounded,
          'name': 'Legendary Week',
          'earned': weeklyAverage >= 130,
        },
        {
          'iconData': Icons.nightlight_round,
          'name': 'Sleep Champ',
          'earned': sleepDoneDays.length >= 5,
        },
      ];

      if (!mounted) return;
      setState(() {
        _weeklyAverage = weeklyAverage;
        _days = builtDays;
        _badges = badges;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
      unawaited(OfflineSyncService.instance.syncNow());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final character = VibeCharacter.getForScore(_weeklyAverage, context.themeColors);

    return Scaffold(
      backgroundColor: context.themeColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'WEEKLY STATEMENT',
          style: GoogleFonts.orbitron(
            color: context.themeColors.neonPurple,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: false,
      ),
      body: (_isLoading && !_hasLoadedOnce)
          ? Center(child: CircularProgressIndicator(color: context.themeColors.neonPurple))
          : _loadError != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadWeeklyData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(20).copyWith(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAverageHero(character),
                        const SizedBox(height: 32),
                        Text(
                          'ACHIEVEMENTS',
                          style: GoogleFonts.orbitron(
                            color: context.themeColors.textSecondary,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 12),
                        _buildBadgesGrid(),
                        const SizedBox(height: 32),
                        Text(
                          'DAY-BY-DAY BREAKDOWN',
                          style: GoogleFonts.orbitron(
                            color: context.themeColors.textSecondary,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                        const SizedBox(height: 12),
                        _buildDailyList(),
                        const SizedBox(height: 32),
                        _buildVibeCharacterCard(character),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FAILED TO LOAD WEEKLY DATA',
              style: GoogleFonts.orbitron(
                color: context.themeColors.neonRed,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _loadError ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(
                color: context.themeColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeeklyData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageHero(VibeCharacter character) {
    return GlowCard(
      glowing: _weeklyAverage >= 90,
      glowColor: character.color,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'WEEKLY AVERAGE',
            style: GoogleFonts.orbitron(
              color: context.themeColors.textSecondary,
              fontSize: 12,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
          GlowText(
            text: '${_weeklyAverage.toStringAsFixed(1)}%',
            glowColor: character.color,
            glowRadius: 16,
            style: GoogleFonts.orbitron(
              color: character.color,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: character.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: character.color.withValues(alpha: 0.5)),
            ),
            child: Text(
              AppColors.getPerformanceLabel(_weeklyAverage),
              style: GoogleFonts.orbitron(
                color: character.color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildBadgesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        final badge = _badges[index];
        final earned = badge['earned'] as bool;
        return _buildBadge(
          icon: badge['iconData'] as IconData,
          name: badge['name'] as String,
          earned: earned,
          delayMs: 400 + (index * 50),
        );
      },
    );
  }

  Widget _buildBadge({required IconData icon, required String name, required bool earned, required int delayMs}) {
    final color = earned ? context.themeColors.gold : context.themeColors.bgCardLight;
    final borderColor = earned ? context.themeColors.gold : context.themeColors.borderSubtle;

    return Container(
      decoration: BoxDecoration(
        color: earned ? color.withValues(alpha: 0.1) : color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: earned ? 1.5 : 1),
        boxShadow: earned ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)] : [],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 30,
            color: earned ? context.themeColors.gold : Colors.grey.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 8),
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: earned ? context.themeColors.textPrimary : context.themeColors.textMuted,
              fontSize: 8,
              fontWeight: earned ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delayMs)).fadeIn().scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildDailyList() {
    return Column(
      children: _days.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        final score = day['score'] as double;
        final color = AppColors.getPerformanceColor(score, context.themeColors);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            collapsedBackgroundColor: context.themeColors.bgCard,
            backgroundColor: context.themeColors.bgCardLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.themeColors.borderSubtle),
            ),
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
              ),
            ),
            title: Text(
              '${day['day']}  •  ${day['date']}',
              style: GoogleFonts.shareTechMono(
                color: context.themeColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Text(
              '${score.toStringAsFixed(0)}%',
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks: ${day['done']}/${day['total']} done',
                      style: GoogleFonts.shareTechMono(
                        color: context.themeColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Missed: ${day['missed']}  •  Progress logs: ${day['progress']}',
                      style: GoogleFonts.shareTechMono(
                        color: context.themeColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Prayers: ${day['prayer']}',
                      style: GoogleFonts.shareTechMono(
                        color: context.themeColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate(delay: Duration(milliseconds: 600 + (index * 50))).fadeIn().slideX(begin: 0.1),
        );
      }).toList(),
    );
  }

  Widget _buildVibeCharacterCard(VibeCharacter character) {
    return GlowCard(
      glowing: true,
      glowColor: character.color,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: character.color.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: character.color.withValues(alpha: 0.3))),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  'WEEKLY VIBE CHARACTER',
                  style: GoogleFonts.orbitron(
                    color: context.themeColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GlowText(
                  text: character.name,
                  glowColor: character.color,
                  glowRadius: 12,
                  style: GoogleFonts.orbitron(
                    color: character.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  character.personality.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    color: context.themeColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  character.color.withValues(alpha: 0.05),
                  context.themeColors.bg,
                ],
              ),
            ),
            child: Center(
              child: Icon(Icons.person_outline, size: 64, color: character.color.withValues(alpha: 0.2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.message_outlined, size: 16, color: character.color),
                    const SizedBox(width: 8),
                    Text(
                      'SYSTEM MESSAGE',
                      style: GoogleFonts.orbitron(
                        color: character.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"${character.message}"',
                  style: GoogleFonts.shareTechMono(
                    color: context.themeColors.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: const Duration(milliseconds: 1000)).fadeIn().slideY(begin: 0.2).shimmer(
          duration: 2500.ms,
          color: character.color.withValues(alpha: 0.4),
        );
  }
}


