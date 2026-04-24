import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/vibe_character.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  // Mock data for weekly UI demonstration
  final double _weeklyAverage = 92.5;
  final List<Map<String, dynamic>> _days = [
    {'day': 'Saturday', 'score': 85.0},
    {'day': 'Sunday', 'score': 92.0},
    {'day': 'Monday', 'score': 105.0},
    {'day': 'Tuesday', 'score': 95.0},
    {'day': 'Wednesday', 'score': 70.0},
    {'day': 'Thursday', 'score': 88.0},
    {'day': 'Friday', 'score': 112.5},
  ];

  final List<Map<String, dynamic>> _badges = [
    {'icon': '🔥', 'name': '5-Day Streak', 'earned': true},
    {'icon': '🕌', 'name': 'Prayer Warrior', 'earned': false},
    {'icon': '💪', 'name': 'Iron Body', 'earned': true},
    {'icon': '🧠', 'name': 'Deep Focus', 'earned': true},
    {'icon': '👑', 'name': 'Legendary Week', 'earned': false},
    {'icon': '🌙', 'name': 'Sleep Champ', 'earned': false},
  ];

  @override
  Widget build(BuildContext context) {
    final character = VibeCharacter.getForScore(_weeklyAverage);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'WEEKLY STATEMENT',
          style: GoogleFonts.orbitron(
            color: AppColors.neonPurple,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20).copyWith(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weekly Average Hero
            _buildAverageHero(character),
            const SizedBox(height: 32),
            
            // Badges Section
            Text(
              'ACHIEVEMENTS',
              style: GoogleFonts.orbitron(
                color: AppColors.textSecondary,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            _buildBadgesGrid(),
            const SizedBox(height: 32),

            // Daily Breakdown
            Text(
              'DAY-BY-DAY BREAKDOWN',
              style: GoogleFonts.orbitron(
                color: AppColors.textSecondary,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 12),
            _buildDailyList(),
            const SizedBox(height: 32),

            // Vibe Character Reveal
            _buildVibeCharacterCard(character),
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
              color: AppColors.textSecondary,
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
          icon: badge['icon'],
          name: badge['name'],
          earned: earned,
          delayMs: 400 + (index * 50),
        );
      },
    );
  }

  Widget _buildBadge({required String icon, required String name, required bool earned, required int delayMs}) {
    final color = earned ? AppColors.gold : AppColors.bgCardLight;
    final borderColor = earned ? AppColors.gold : AppColors.borderSubtle;
    
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
          Text(
            icon,
            style: TextStyle(
              fontSize: 28,
              foreground: !earned ? (Paint()..color = Colors.grey.withValues(alpha: 0.3)) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: earned ? AppColors.textPrimary : AppColors.textMuted,
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
        final color = AppColors.getPerformanceColor(score);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            collapsedBackgroundColor: AppColors.bgCard,
            backgroundColor: AppColors.bgCardLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderSubtle),
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
              day['day'],
              style: GoogleFonts.shareTechMono(
                color: AppColors.textPrimary,
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
                child: Text(
                  'Detailed task breakdown would appear here.\n(Connected to local database)',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
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
          // Header
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
                    color: AppColors.textSecondary,
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
                    color: AppColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Visual Description placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  character.color.withValues(alpha: 0.05),
                  AppColors.bg,
                ],
              ),
            ),
            child: Center(
              child: Icon(Icons.person_outline, size: 64, color: character.color.withValues(alpha: 0.2)),
            ),
          ),

          // Message
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
                    color: AppColors.textPrimary,
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
    ).animate(delay: const Duration(milliseconds: 1000)).fadeIn().slideY(begin: 0.2).shimmer(duration: 2500.ms, color: character.color.withValues(alpha: 0.4));
  }
}
