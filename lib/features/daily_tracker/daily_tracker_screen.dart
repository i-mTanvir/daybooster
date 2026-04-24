import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/task_entry.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';

class DailyTrackerScreen extends StatefulWidget {
  final DayData todayData;

  const DailyTrackerScreen({super.key, required this.todayData});

  @override
  State<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends State<DailyTrackerScreen> {
  late List<TaskEntry> _tasks;

  @override
  void initState() {
    super.initState();
    // Working with a local copy for the UI to update
    _tasks = List.from(widget.todayData.tasks);
  }

  void _updateBinaryTask(int index, bool value) {
    HapticFeedback.lightImpact();
    setState(() {
      _tasks[index] = _tasks[index].copyWith(done: value);
    });
  }

  void _updateMinutesTask(int index, double value) {
    HapticFeedback.selectionClick();
    setState(() {
      _tasks[index] = _tasks[index].copyWith(actualMinutes: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DAILY TRACKER',
          style: GoogleFonts.orbitron(
            color: AppColors.neonGreen,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
            onPressed: () {
              // Reset today's inputs
              setState(() {
                _tasks = buildDefaultTasks();
              });
            },
            tooltip: 'Reset Today',
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20).copyWith(bottom: 100),
        physics: const BouncingScrollPhysics(),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTaskCard(task, index),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskEntry task, int index) {
    final pct = task.percentage;
    final color = AppColors.getPerformanceColor(pct);
    final hasData = task.actualMinutes != null || task.done != null;
    final cardGlowColor = hasData ? color : AppColors.borderSubtle;

    return GlowCard(
      glowing: hasData && pct >= 90,
      glowColor: cardGlowColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(task.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    if (task.targetMinutes != null || task.type == TaskType.inverse)
                      Text(
                        task.type == TaskType.inverse
                            ? 'Max: 60 min'
                            : 'Target: ${task.targetMinutes} min',
                        style: GoogleFonts.shareTechMono(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: GoogleFonts.orbitron(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputControl(task, index),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.05);
  }

  Widget _buildInputControl(TaskEntry task, int index) {
    if (task.type == TaskType.binary) {
      final isDone = task.done == true;
      return Row(
        children: [
          Expanded(
            child: _buildBinaryButton(
              title: 'MISSED',
              isSelected: task.done == false,
              color: AppColors.neonRed,
              onTap: () => _updateBinaryTask(index, false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildBinaryButton(
              title: 'DONE',
              isSelected: isDone,
              color: AppColors.neonGreen,
              onTap: () => _updateBinaryTask(index, true),
            ),
          ),
        ],
      );
    } else {
      // Minutes / Inverse slider
      final maxSliderVal = (task.targetMinutes != null)
          ? task.targetMinutes! * 1.5 // Allow up to 150% of target on slider
          : 120.0; // Fallback for inverse task (e.g. device use)
      
      final currentVal = task.actualMinutes ?? 0.0;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOG MINUTES:',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                '${currentVal.toInt()}m',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.electricBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.electricBlue,
              inactiveTrackColor: AppColors.bgCardLight,
              thumbColor: AppColors.electricBlue,
              overlayColor: AppColors.electricBlue.withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: currentVal.clamp(0, maxSliderVal),
              min: 0,
              max: maxSliderVal,
              divisions: maxSliderVal.toInt(),
              onChanged: (val) => _updateMinutesTask(index, val),
            ),
          ),
        ],
      );
    }
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
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.orbitron(
              color: isSelected ? color : AppColors.textMuted,
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
