import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glow_card.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController(text: '60');
  final _metricController = TextEditingController(text: 'Minutes');

  int _selectedCategoryIndex = 0;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  int _durationMinutes = 60;
  final List<bool> _selectedDays = List.generate(7, (index) => true); // S M T W T F S
  bool _isProgress = true;
  bool _isFocusMode = false;

  final List<String> _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _metricController.dispose();
    super.dispose();
  }

  void _saveTask() {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('DIRECTIVE SAVED: ${_nameController.text}'),
    //     backgroundColor: context.themeColors.electricBlue,
    //   ),
    // );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    final categories = [
      {'name': 'Gym', 'emoji': '🏋️', 'color': colors.neonRed},
      {'name': 'Read', 'emoji': '📖', 'color': colors.neonPurple},
      {'name': 'Code', 'emoji': '💻', 'color': colors.electricBlue},
      {'name': 'Work', 'emoji': '💼', 'color': colors.gold},
      {'name': 'Prayer', 'emoji': '🕌', 'color': colors.neonGreen},
      {'name': 'Custom', 'emoji': '✨', 'color': colors.textPrimary},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.electricBlue.withValues(alpha: 0.3), width: 1)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NEW DIRECTIVE',
                  style: GoogleFonts.orbitron(
                    color: colors.electricBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Basic Intel
                _buildSectionHeader('1. PROTOCOL NAME'),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.orbitron(color: colors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter task name...',
                    hintStyle: GoogleFonts.orbitron(color: colors.textMuted),
                    filled: true,
                    fillColor: colors.bgCardLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.electricBlue, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('CATEGORY MATRIX'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategoryIndex == index;
                      final cColor = cat['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategoryIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? cColor.withValues(alpha: 0.15) : colors.bgCardLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? cColor : colors.borderSubtle,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cat['emoji'] as String, style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(
                                cat['name'] as String,
                                style: GoogleFonts.orbitron(
                                  color: isSelected ? cColor : colors.textMuted,
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Temporal Parameters
                _buildSectionHeader('2. TEMPORAL PARAMETERS'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeButton(
                        'START TIME',
                        _startTime.format(context),
                        () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (time != null) {
                            setState(() => _startTime = time);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeButton(
                        'DURATION',
                        '$_durationMinutes min',
                        () {
                          // Simplistic duration toggle for mock
                          setState(() {
                            _durationMinutes += 15;
                            if (_durationMinutes > 180) _durationMinutes = 15;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'ACTIVE DAYS',
                  style: GoogleFonts.orbitron(
                    color: colors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final isSelected = _selectedDays[index];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDays[index] = !isSelected);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? colors.electricBlue.withValues(alpha: 0.2) : colors.bgCardLight,
                          border: Border.all(
                            color: isSelected ? colors.electricBlue : colors.borderSubtle,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _dayLabels[index],
                            style: GoogleFonts.orbitron(
                              color: isSelected ? colors.electricBlue : colors.textMuted,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // 3. Tracking Protocol
                _buildSectionHeader('3. TRACKING PROTOCOL'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.bgCardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isProgress = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isProgress ? colors.neonPurple.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'BINARY (DONE/MISS)',
                                style: GoogleFonts.orbitron(
                                  color: !_isProgress ? colors.neonPurple : colors.textMuted,
                                  fontSize: 11,
                                  fontWeight: !_isProgress ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isProgress = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isProgress ? colors.electricBlue.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'PROGRESS',
                                style: GoogleFonts.orbitron(
                                  color: _isProgress ? colors.electricBlue : colors.textMuted,
                                  fontSize: 11,
                                  fontWeight: _isProgress ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_isProgress) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.orbitron(color: colors.textPrimary, fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'TARGET',
                            labelStyle: GoogleFonts.orbitron(color: colors.textMuted, fontSize: 10),
                            filled: true,
                            fillColor: colors.bgCardLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _metricController,
                          style: GoogleFonts.orbitron(color: colors.textPrimary, fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'METRIC (e.g. Minutes, Pages)',
                            labelStyle: GoogleFonts.orbitron(color: colors.textMuted, fontSize: 10),
                            filled: true,
                            fillColor: colors.bgCardLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                ],
                const SizedBox(height: 32),

                // 4. Focus Mode
                _buildSectionHeader('4. OVERRIDES'),
                const SizedBox(height: 12),
                GlowCard(
                  glowColor: _isFocusMode ? colors.gold : colors.borderSubtle,
                  glowing: _isFocusMode,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, color: _isFocusMode ? colors.gold : colors.textMuted),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEEP FOCUS MODE',
                                style: GoogleFonts.orbitron(
                                  color: colors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Marks block as high-priority',
                                style: GoogleFonts.shareTechMono(
                                  color: colors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isFocusMode,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _isFocusMode = val);
                        },
                        activeColor: colors.gold,
                        activeTrackColor: colors.gold.withValues(alpha: 0.3),
                        inactiveThumbColor: colors.textMuted,
                        inactiveTrackColor: colors.bgCardLight,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.neonGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: colors.neonGreen.withValues(alpha: 0.5),
                    ),
                    child: Text(
                      'INITIALIZE DIRECTIVE',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.orbitron(
            color: context.themeColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: context.themeColors.borderSubtle,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: context.themeColors.bgCardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.themeColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.orbitron(
                color: context.themeColors.textMuted,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.shareTechMono(
                color: context.themeColors.electricBlue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
