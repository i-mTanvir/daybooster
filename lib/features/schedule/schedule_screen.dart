import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';
import 'widgets/add_task_sheet.dart';

class ScheduleBlock {
  final String id;
  final String time;
  final String name;
  final String duration;
  final Color glowColor;

  ScheduleBlock({
    required this.id,
    required this.time,
    required this.name,
    required this.duration,
    required this.glowColor,
  });
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDayIndex = 0; // 0 = Sat, 6 = Fri (matching BD/ME week start)
  late List<ScheduleBlock> _blocks;

  final List<String> _days = ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI'];

  @override
  void initState() {
    super.initState();
    // Defer initialization to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetToDefault();
  }

  void _resetToDefault() {
    setState(() {
      _blocks = [
        ScheduleBlock(id: '1', time: '05:30', name: 'Wake Up', duration: '—', glowColor: context.themeColors.borderSubtle),
        ScheduleBlock(id: '2', time: '05:35', name: 'Fajr Namaz', duration: '25 min', glowColor: context.themeColors.gold),
        ScheduleBlock(id: '3', time: '06:00', name: 'Workout', duration: '45 min', glowColor: context.themeColors.neonRed),
        ScheduleBlock(id: '4', time: '06:45', name: 'Shower + Breakfast', duration: '30 min', glowColor: context.themeColors.electricBlue),
        ScheduleBlock(id: '5', time: '07:15', name: 'Skill Block #1', duration: '2 hr', glowColor: context.themeColors.neonPurple),
        ScheduleBlock(id: '6', time: '09:15', name: 'Short Break', duration: '15 min', glowColor: context.themeColors.borderSubtle),
        ScheduleBlock(id: '7', time: '09:30', name: 'Skill Block #2', duration: '2 hr', glowColor: context.themeColors.neonPurple),
        ScheduleBlock(id: '8', time: '11:30', name: 'Lunch', duration: '30 min', glowColor: context.themeColors.electricBlue),
        ScheduleBlock(id: '9', time: '12:15', name: 'Dhuhr Namaz', duration: '30 min', glowColor: context.themeColors.gold),
        ScheduleBlock(id: '10', time: '12:45', name: 'Project / Build Time', duration: '2 hr', glowColor: context.themeColors.neonGreen),
        ScheduleBlock(id: '11', time: '14:45', name: 'Break', duration: '15 min', glowColor: context.themeColors.borderSubtle),
        ScheduleBlock(id: '12', time: '15:00', name: 'Asr Namaz', duration: '30 min', glowColor: context.themeColors.gold),
        ScheduleBlock(id: '13', time: '15:30', name: 'Skill Block #3 / Reading', duration: '1.5 hr', glowColor: context.themeColors.neonPurple),
        ScheduleBlock(id: '14', time: '17:00', name: 'Family Time', duration: '30 min', glowColor: context.themeColors.electricBlue),
        ScheduleBlock(id: '15', time: '17:30', name: 'Walk / Rest', duration: '30 min', glowColor: context.themeColors.borderSubtle),
        ScheduleBlock(id: '16', time: '18:15', name: 'Maghrib Namaz', duration: '30 min', glowColor: context.themeColors.gold),
        ScheduleBlock(id: '17', time: '18:45', name: 'Dinner', duration: '30 min', glowColor: context.themeColors.electricBlue),
        ScheduleBlock(id: '18', time: '19:15', name: 'Isha Namaz', duration: '30 min', glowColor: context.themeColors.gold),
        ScheduleBlock(id: '19', time: '19:45', name: 'Review + Journal + Next Day', duration: '1.25 hr', glowColor: context.themeColors.neonGreen),
        ScheduleBlock(id: '20', time: '21:00', name: 'Free Zone / Devices', duration: '1 hr', glowColor: context.themeColors.neonYellow),
        ScheduleBlock(id: '21', time: '22:00', name: 'Sleep', duration: '—', glowColor: context.themeColors.borderSubtle),
      ];
    });
  }

  void _editBlock(int index) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Edit logic for ${_blocks[index].name} coming soon.')),
    // );
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
        actions: [
          TextButton.icon(
            onPressed: _resetToDefault,
            icon: Icon(Icons.restore, color: context.themeColors.neonRed, size: 16),
            label: Text(
              'RESET',
              style: GoogleFonts.orbitron(
                color: context.themeColors.neonRed,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 100),
              physics: const BouncingScrollPhysics(),
              itemCount: _blocks.length,
              itemBuilder: (context, index) {
                return _buildTimelineItem(_blocks[index], index);
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
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddTaskSheet(),
            );
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
                onTap: () => _editBlock(index),
                child: GlowCard(
                  glowing: false,
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
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: context.themeColors.textMuted.withValues(alpha: 0.5),
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

