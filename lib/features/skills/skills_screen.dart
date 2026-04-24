import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';

class SkillDay {
  final String dayName;
  final String defaultSkill;
  final String prompt;
  String currentSkill;
  String note;

  SkillDay({
    required this.dayName,
    required this.defaultSkill,
    required this.prompt,
    this.currentSkill = '',
    this.note = '',
  }) {
    if (currentSkill.isEmpty) currentSkill = defaultSkill;
  }
}

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  late List<SkillDay> _skillDays;

  @override
  void initState() {
    super.initState();
    _skillDays = [
      SkillDay(dayName: 'Saturday', defaultSkill: 'Python + Mini Project', prompt: 'What did I build today?'),
      SkillDay(dayName: 'Sunday', defaultSkill: 'DSA — Arrays, Strings, Recursion', prompt: 'Which problems did I solve?'),
      SkillDay(dayName: 'Monday', defaultSkill: 'Web Dev — HTML/CSS/JS or Flutter', prompt: 'What did I ship?'),
      SkillDay(dayName: 'Tuesday', defaultSkill: 'AI/ML — Watch + Implement', prompt: 'What concept did I apply?'),
      SkillDay(dayName: 'Wednesday', defaultSkill: 'System Design + Database', prompt: 'What did I design today?'),
      SkillDay(dayName: 'Thursday', defaultSkill: 'Open Source / GitHub', prompt: 'What did I contribute?'),
      SkillDay(dayName: 'Friday', defaultSkill: 'Weekly Review + Quran + Rest', prompt: 'What was my best moment?'),
    ];
  }

  void _editSkill(int index) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Edit logic for ${_skillDays[index].dayName} skill coming soon.')),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SKILLS MATRIX',
          style: GoogleFonts.orbitron(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20).copyWith(bottom: 100),
        physics: const BouncingScrollPhysics(),
        itemCount: _skillDays.length,
        itemBuilder: (context, index) {
          final skill = _skillDays[index];
          // Use today's index to highlight current day (Sat=0..Fri=6 mapping not fully robust here, just using gold for all for now)
          // We could map DateTime.now().weekday, but let's just make them all look cool.
          final isToday = DateTime.now().weekday == (index + 6) % 7 + 1; // Basic mapping

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSkillCard(skill, index, isToday),
          );
        },
      ),
    );
  }

  Widget _buildSkillCard(SkillDay skill, int index, bool isToday) {
    return GlowCard(
      glowing: isToday,
      glowColor: isToday ? AppColors.gold : AppColors.electricBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isToday) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.6), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    skill.dayName.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: isToday ? AppColors.gold : AppColors.textSecondary,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _editSkill(index),
                child: Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Skill Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.psychology_outlined, color: AppColors.textPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skill.currentSkill,
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Daily Note Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.prompt,
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextField(
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tap to log your progress...',
                    hintStyle: GoogleFonts.shareTechMono(
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  onChanged: (val) {
                    skill.note = val;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideY(begin: 0.1);
  }
}
