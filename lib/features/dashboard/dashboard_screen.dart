import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/task_entry.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/glow_card.dart';

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
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  late DayData _todayData;

  final List<String> _motivationalQuotes = [
    "You are not building a routine. You are building a legacy.",
    "Every prayer is armor. Every skill block is a weapon forged.",
    "Discipline is not a prison. It is a superpower.",
    "The Architect does not wait for motivation. He creates it.",
    "Your future self is watching. Don't disappoint him.",
    "Excellence is not an act. It is a habit.",
    "Build the system. Trust the process. Become the legend.",
  ];

  late String _quote;

  @override
  void initState() {
    super.initState();
    _todayData = widget.todayData ??
        DayData(date: DateTime.now(), tasks: buildDefaultTasks());
    _quote = _motivationalQuotes[math.Random().nextInt(_motivationalQuotes.length)];

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
    
    // Check if initial score is legendary
    if (_todayData.dayScore >= 130) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _gridController.dispose();
    _scoreController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = _todayData.dayScore;
    final scoreColor = AppColors.getPerformanceColor(score);
    final scoreLabel = AppColors.getPerformanceLabel(score);
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final dateStr = DateFormat('d MMM yyyy').format(now);
    final completedTasks = _todayData.tasks.where((t) => t.percentage >= 100).length;
    final totalTasks = _todayData.tasks.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Animated cyberpunk grid background
          AnimatedBuilder(
            animation: _gridController,
            builder: (_, __) => CustomPaint(
              painter: CyberpunkGridPainter(_gridController.value),
              size: Size.infinite,
            ),
          ),

          // Radial glow at top-right
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
                    AppColors.neonPurple.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top bar
                SliverToBoxAdapter(child: _buildTopBar(dayName, dateStr)),

                // Greeting + Quote
                SliverToBoxAdapter(child: _buildGreeting()),

                // Day Score Arc
                SliverToBoxAdapter(
                  child: _buildDayScoreCard(score, scoreColor, scoreLabel),
                ),

                // Quick Stats Row
                SliverToBoxAdapter(
                  child: _buildQuickStats(completedTasks, totalTasks),
                ),

                // Prayer Status
                SliverToBoxAdapter(child: _buildPrayerStatus()),

                // Top Tasks Preview
                SliverToBoxAdapter(child: _buildTopTasksPreview()),

                // Bottom spacing for nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // Particle Burst (Confetti) for Legendary Score
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14159 / 2, // Downwards
              maxBlastForce: 25,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                AppColors.gold,
                AppColors.electricBlue,
                AppColors.neonPurple,
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
                  color: AppColors.electricBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.electricBlue.withValues(alpha: 0.3 + 0.2 * _pulseController.value),
                  width: 1,
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.electricBlue.withValues(alpha: 0.08),
                    AppColors.neonPurple.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: AppColors.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.orbitron(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
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
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          GlowText(
            text: 'The System\nAwaits.',
            glowColor: AppColors.electricBlue,
            glowRadius: 12,
            style: GoogleFonts.orbitron(
              color: AppColors.textPrimary,
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
              color: AppColors.bgCardLight,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote, color: AppColors.neonPurple, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _quote,
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scoreColor.withValues(alpha: 0.15),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.4), width: 1),
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
                              color: AppColors.textMuted,
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScaleLegendDot(AppColors.perfCritical, '0–39'),
                _buildScaleLegendDot(AppColors.perfWeak, '40–59'),
                _buildScaleLegendDot(AppColors.perfBelowTarget, '60–79'),
                _buildScaleLegendDot(AppColors.perfAlmost, '80–89'),
                _buildScaleLegendDot(AppColors.perfTarget, '90–110'),
                _buildScaleLegendDot(AppColors.perfOverdrive, '111–130'),
                _buildScaleLegendDot(AppColors.perfLegendary, '131+'),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildScaleLegendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int completed, int total) {
    final prayersDone = _todayData.tasks
        .where((t) => ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'].contains(t.id) && t.done == true)
        .length;

    final skillMinutes = _todayData.tasks
        .where((t) => ['skill1', 'skill2', 'skill3', 'project'].contains(t.id))
        .fold(0.0, (sum, t) => sum + (t.actualMinutes ?? 0));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline,
              iconColor: AppColors.neonGreen,
              value: '$completed/$total',
              label: 'TASKS DONE',
              glowColor: AppColors.neonGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.mosque_outlined,
              iconColor: AppColors.gold,
              value: '$prayersDone/5',
              label: 'PRAYERS',
              glowColor: prayersDone == 5 ? AppColors.gold : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.timer_outlined,
              iconColor: AppColors.electricBlue,
              value: '${skillMinutes.toInt()}m',
              label: 'FOCUS TIME',
              glowColor: AppColors.electricBlue,
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
              color: AppColors.textMuted,
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
    final prayers = [
      {'id': 'fajr', 'name': 'Fajr', 'time': '05:35'},
      {'id': 'dhuhr', 'name': 'Dhuhr', 'time': '12:15'},
      {'id': 'asr', 'name': 'Asr', 'time': '15:00'},
      {'id': 'maghrib', 'name': 'Maghrib', 'time': '18:15'},
      {'id': 'isha', 'name': 'Isha', 'time': '19:15'},
    ];

    final allDone = _todayData.allPrayersDone;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlowCard(
        glowColor: allDone ? AppColors.gold : AppColors.neonPurple,
        glowing: allDone,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('🕌', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'DAILY PRAYERS',
                      style: GoogleFonts.orbitron(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                if (allDone)
                  GlowText(
                    text: '✦ COMPLETE',
                    glowColor: AppColors.gold,
                    glowRadius: 8,
                    style: GoogleFonts.orbitron(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: prayers.map((p) {
                final task = _todayData.tasks.firstWhere(
                  (t) => t.id == p['id'],
                  orElse: () => TaskEntry(
                    id: '', name: '', emoji: '', type: TaskType.binary, done: false,
                  ),
                );
                final done = task.done == true;
                return _buildPrayerDot(
                  name: p['name']!,
                  time: p['time']!,
                  done: done,
                );
              }).toList(),
            ),
          ],
        ),
      ).animate(target: allDone ? 1 : 0).shimmer(duration: 2000.ms, color: AppColors.gold.withValues(alpha: 0.3)),
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
            color: done ? AppColors.gold.withValues(alpha: 0.15) : AppColors.bgCardLight,
            border: Border.all(
              color: done ? AppColors.gold : AppColors.borderSubtle,
              width: done ? 2 : 1,
            ),
            boxShadow: done
                ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 12)]
                : [],
          ),
          child: Center(
            child: done
                ? Icon(Icons.star, color: AppColors.gold, size: 18)
                : Text('🕌', style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.orbitron(
            color: done ? AppColors.gold : AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          time,
          style: GoogleFonts.shareTechMono(
            color: AppColors.textMuted,
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
        glowColor: AppColors.neonPurple,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TODAY\'S QUESTS',
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'VIEW ALL →',
                  style: GoogleFonts.orbitron(
                    color: AppColors.electricBlue,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
    final color = AppColors.getPerformanceColor(pct > 0 ? pct : 0);
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
                    Text(
                      task.name,
                      style: GoogleFonts.orbitron(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasData ? '${pct.toStringAsFixed(0)}%' : '--',
                      style: GoogleFonts.shareTechMono(
                        color: hasData ? color : AppColors.textMuted,
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
                    backgroundColor: AppColors.bgCardMid,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      hasData ? color : AppColors.textMuted,
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
