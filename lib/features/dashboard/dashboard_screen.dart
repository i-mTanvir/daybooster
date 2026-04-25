import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/task_entry.dart';
import '../../core/state/app_refresh_bus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/painters.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String architectName;
  final DayData? todayData;

  const DashboardScreen({
    super.key,
    required this.architectName,
    this.todayData,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  late AnimationController _scoreController;
  late AnimationController _pulseController;
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));

  late DayData _todayData;
  bool _isLoading = true;
  String? _loadError;
  List<_PrayerStatusItem> _prayerItems = [];

  final List<String> _motivationalQuotes = [
    'You are not building a routine. You are building a legacy.',
    'Every prayer is armor. Every skill block is a weapon forged.',
    'Discipline is not a prison. It is a superpower.',
    'The Architect does not wait for motivation. He creates it.',
    'Your future self is watching. Don\'t disappoint him.',
    'Excellence is not an act. It is a habit.',
    'Build the system. Trust the process. Become the legend.',
  ];

  late String _quote;

  @override
  void initState() {
    super.initState();
    _todayData = widget.todayData ?? DayData(date: DateTime.now(), tasks: []);
    _quote =
        _motivationalQuotes[math.Random().nextInt(_motivationalQuotes.length)];

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    AppRefreshBus.notifier.addListener(_handleGlobalRefresh);
    _loadTodayData();
  }

  @override
  void dispose() {
    AppRefreshBus.notifier.removeListener(_handleGlobalRefresh);
    _gridController.dispose();
    _scoreController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _handleGlobalRefresh() {
    if (!mounted) return;
    _loadTodayData();
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
    const prayerKeywords = [
      'fajr',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
      'prayer',
      'namaz'
    ];
    return emoji == '🕌' || prayerKeywords.any(name.contains);
  }

  Future<void> _loadTodayData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No active session found.');
      }

      final now = DateTime.now();
      final dayIndex = _getDayIndex(now);
      final todayDate = _formatDate(now);

      final directivesResponse = await Supabase.instance.client
          .from('directives')
          .select()
          .eq('user_id', user.id);
      final allDirectives =
          (directivesResponse as List<dynamic>).cast<Map<String, dynamic>>();

      final todaysDirectives = allDirectives.where((directive) {
        final days =
            List<int>.from((directive['active_days'] as List<dynamic>?) ?? []);
        return days.contains(dayIndex);
      }).toList()
        ..sort((a, b) {
          final startA = (a['start_time'] as String? ?? '00:00');
          final startB = (b['start_time'] as String? ?? '00:00');
          return startA.compareTo(startB);
        });

      final directiveIds = todaysDirectives
          .map((directive) => directive['id']?.toString())
          .whereType<String>()
          .toList();

      final Map<String, Map<String, dynamic>> logsByDirective = {};
      if (directiveIds.isNotEmpty) {
        final logsResponse = await Supabase.instance.client
            .from('daily_logs')
            .select()
            .eq('log_date', todayDate)
            .inFilter('directive_id', directiveIds);

        for (final row in (logsResponse as List<dynamic>)
            .cast<Map<String, dynamic>>()) {
          final key = row['directive_id']?.toString();
          if (key != null) {
            logsByDirective[key] = row;
          }
        }
      }

      final List<TaskEntry> tasks = [];
      final List<_PrayerStatusItem> prayerItems = [];

      for (final directive in todaysDirectives) {
        final directiveId = directive['id']?.toString() ?? '';
        if (directiveId.isEmpty) continue;

        final trackingType =
            (directive['tracking_type'] as String? ?? 'binary').toLowerCase();
        final log = logsByDirective[directiveId];
        final progressValue = (log?['progress_value'] as num?)?.toDouble();
        final isDone = log?['is_done'] as bool?;
        final targetMetric = (directive['target_metric'] as num?)?.toInt();
        final durationMinutes = (directive['duration_minutes'] as int?) ?? 0;

        final taskType = switch (trackingType) {
          'progress' => TaskType.minutes,
          'inverse' => TaskType.inverse,
          _ => TaskType.binary,
        };

        tasks.add(
          TaskEntry(
            id: directiveId,
            name: directive['name'] as String? ?? 'Untitled',
            emoji: directive['category_emoji'] as String? ?? '⚡',
            type: taskType,
            targetMinutes: taskType == TaskType.binary
                ? null
                : (targetMetric != null && targetMetric > 0
                    ? targetMetric
                    : durationMinutes),
            actualMinutes: taskType == TaskType.binary ? null : progressValue,
            done: taskType == TaskType.binary ? isDone : null,
          ),
        );

        if (_looksLikePrayer(directive)) {
          final timeRaw = directive['start_time'] as String?;
          final timeLabel =
              (timeRaw != null && timeRaw.length >= 5) ? timeRaw.substring(0, 5) : '--:--';
          prayerItems.add(
            _PrayerStatusItem(
              name: directive['name'] as String? ?? 'Prayer',
              time: timeLabel,
              done: isDone == true,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _todayData = DayData(date: now, tasks: tasks);
        _prayerItems = prayerItems;
        _isLoading = false;
      });

      if (_todayData.dayScore >= 130) {
        _confettiController.play();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
        _todayData = DayData(date: DateTime.now(), tasks: []);
        _prayerItems = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _todayData.dayScore;
    final scoreColor = AppColors.getPerformanceColor(score, context.themeColors);
    final scoreLabel = AppColors.getPerformanceLabel(score);
    final now = _todayData.date;
    final dayName = DateFormat('EEEE').format(now);
    final dateStr = DateFormat('d MMM yyyy').format(now);
    final completedTasks =
        _todayData.tasks.where((t) => t.percentage >= 100).length;
    final totalTasks = _todayData.tasks.length;

    return Scaffold(
      backgroundColor: context.themeColors.bg,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _gridController,
            builder: (_, __) => CustomPaint(
              painter: CyberpunkGridPainter(_gridController.value),
              size: Size.infinite,
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.themeColors.neonPurple.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadTodayData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar(dayName, dateStr)),
                  SliverToBoxAdapter(child: _buildGreeting()),
                  SliverToBoxAdapter(
                    child: _buildDayScoreCard(score, scoreColor, scoreLabel),
                  ),
                  SliverToBoxAdapter(
                    child: _buildQuickStats(completedTasks, totalTasks),
                  ),
                  SliverToBoxAdapter(child: _buildPrayerStatus()),
                  SliverToBoxAdapter(child: _buildTopTasksPreview()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: context.themeColors.bg.withValues(alpha: 0.65),
              child: Center(
                child: CircularProgressIndicator(
                  color: context.themeColors.electricBlue,
                ),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 25,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: [
                context.themeColors.gold,
                context.themeColors.electricBlue,
                context.themeColors.neonPurple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String dayName, String dateStr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName.toUpperCase(),
                style: GoogleFonts.orbitron(
                  color: context.themeColors.electricBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: GoogleFonts.shareTechMono(
                  color: context.themeColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: Icon(
              Icons.person_outline,
              color: context.themeColors.textPrimary,
              size: 22,
            ),
            tooltip: 'Architect Profile',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARCHITECT ${widget.architectName.toUpperCase()}',
            style: GoogleFonts.orbitron(
              color: context.themeColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          GlowText(
            text: 'The System\nAwaits.',
            glowColor: context.themeColors.electricBlue,
            glowRadius: 12,
            style: GoogleFonts.orbitron(
              color: context.themeColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: context.themeColors.bgCardLight,
              border: Border.all(color: context.themeColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote,
                    color: context.themeColors.neonPurple, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _quote,
                    style: GoogleFonts.shareTechMono(
                      color: context.themeColors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loadError != null) ...[
            const SizedBox(height: 10),
            Text(
              'Data sync issue: $_loadError',
              style: GoogleFonts.shareTechMono(
                color: context.themeColors.neonRed,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 700.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildDayScoreCard(double score, Color scoreColor, String scoreLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GlowCard(
        glowColor: scoreColor,
        glowing: score >= 90,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DAY SCORE',
                  style: GoogleFonts.orbitron(
                    color: context.themeColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scoreColor.withValues(alpha: 0.15),
                    border: Border.all(
                        color: scoreColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(
                    scoreLabel,
                    style: GoogleFonts.orbitron(
                      color: scoreColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _scoreController,
              builder: (_, __) {
                final animScore = score * _scoreController.value;
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: ArcScorePainter(
                          percentage: animScore,
                          color: scoreColor,
                          strokeWidth: 14,
                        ),
                        size: const Size(200, 200),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GlowText(
                            text: '${animScore.toStringAsFixed(1)}%',
                            glowColor: scoreColor,
                            glowRadius: 16,
                            style: GoogleFonts.orbitron(
                              color: scoreColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TODAY',
                            style: GoogleFonts.orbitron(
                              color: context.themeColors.textMuted,
                              fontSize: 10,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildQuickStats(int completed, int total) {
    final prayersDone = _prayerItems.where((p) => p.done).length;
    final prayersTotal = _prayerItems.length;

    final skillMinutes = _todayData.tasks
        .where((t) => t.type != TaskType.binary)
        .fold(0.0, (sum, t) => sum + (t.actualMinutes ?? 0));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline,
              iconColor: context.themeColors.neonGreen,
              value: '$completed/$total',
              label: 'TASKS DONE',
              glowColor: context.themeColors.neonGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.mosque_outlined,
              iconColor: context.themeColors.gold,
              value: '$prayersDone/$prayersTotal',
              label: 'PRAYERS',
              glowColor: prayersTotal > 0 && prayersDone == prayersTotal
                  ? context.themeColors.gold
                  : context.themeColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.timer_outlined,
              iconColor: context.themeColors.electricBlue,
              value: '${skillMinutes.toInt()}m',
              label: 'FOCUS TIME',
              glowColor: context.themeColors.electricBlue,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color glowColor,
  }) {
    return GlowCard(
      glowColor: glowColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          GlowText(
            text: value,
            glowColor: glowColor,
            glowRadius: 6,
            style: GoogleFonts.orbitron(
              color: glowColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: context.themeColors.textMuted,
              fontSize: 8,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerStatus() {
    final allDone =
        _prayerItems.isNotEmpty && _prayerItems.every((item) => item.done);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlowCard(
        glowColor:
            allDone ? context.themeColors.gold : context.themeColors.neonPurple,
        glowing: allDone,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('🕌', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'DAILY PRAYERS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.orbitron(
                            color: context.themeColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (allDone) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: GlowText(
                        text: '✦ COMPLETE',
                        glowColor: context.themeColors.gold,
                        glowRadius: 8,
                        style: GoogleFonts.orbitron(
                          color: context.themeColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (_prayerItems.isEmpty)
              Text(
                'No prayer directives scheduled for today.',
                style: GoogleFonts.shareTechMono(
                  color: context.themeColors.textMuted,
                  fontSize: 10,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _prayerItems.map((prayer) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildPrayerDot(
                        name: prayer.name,
                        time: prayer.time,
                        done: prayer.done,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ).animate(target: allDone ? 1 : 0).shimmer(
            duration: 2000.ms,
            color: context.themeColors.gold.withValues(alpha: 0.3),
          ),
    ).animate().fadeIn(delay: 700.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPrayerDot({
    required String name,
    required String time,
    required bool done,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? context.themeColors.gold.withValues(alpha: 0.15)
                : context.themeColors.bgCardLight,
            border: Border.all(
              color: done
                  ? context.themeColors.gold
                  : context.themeColors.borderSubtle,
              width: done ? 2 : 1,
            ),
            boxShadow: done
                ? [
                    BoxShadow(
                        color:
                            context.themeColors.gold.withValues(alpha: 0.4),
                        blurRadius: 12)
                  ]
                : [],
          ),
          child: Center(
            child: done
                ? Icon(Icons.star, color: context.themeColors.gold, size: 18)
                : const Text('🕌', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.orbitron(
            color: done
                ? context.themeColors.gold
                : context.themeColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          time,
          style: GoogleFonts.shareTechMono(
            color: context.themeColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildTopTasksPreview() {
    final topTasks = _todayData.tasks.take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlowCard(
        glowColor: context.themeColors.neonPurple,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'TODAY\'S QUESTS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.orbitron(
                      color: context.themeColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'VIEW ALL →',
                      maxLines: 1,
                      style: GoogleFonts.orbitron(
                        color: context.themeColors.electricBlue,
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topTasks.isEmpty)
              Text(
                'No directives planned for today.',
                style: GoogleFonts.shareTechMono(
                  color: context.themeColors.textMuted,
                  fontSize: 11,
                ),
              )
            else
              ...topTasks.asMap().entries.map((entry) {
                final i = entry.key;
                final task = entry.value;
                return _buildTaskRow(task, i);
              }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTaskRow(TaskEntry task, int index) {
    final pct = task.percentage;
    final color = AppColors.getPerformanceColor(
      pct > 0 ? pct : 0,
      context.themeColors,
    );
    final hasData = task.actualMinutes != null || task.done != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(task.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.orbitron(
                          color: context.themeColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasData ? '${pct.toStringAsFixed(0)}%' : '--',
                      style: GoogleFonts.shareTechMono(
                        color: hasData ? color : context.themeColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hasData ? (pct / 130).clamp(0.0, 1.0) : 0,
                    backgroundColor: context.themeColors.borderSubtle,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      hasData ? color : context.themeColors.textMuted,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 900 + index * 80)).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}

class _PrayerStatusItem {
  final String name;
  final String time;
  final bool done;

  const _PrayerStatusItem({
    required this.name,
    required this.time,
    required this.done,
  });
}
