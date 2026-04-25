import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/offline_sync_service.dart';
import '../../core/state/app_refresh_bus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';

class SkillItem {
  final String id;
  final int dayIndex;
  final String name;
  final String prompt;
  final String note;
  final String emoji;

  const SkillItem({
    required this.id,
    required this.dayIndex,
    required this.name,
    required this.prompt,
    required this.note,
    required this.emoji,
  });

  SkillItem copyWith({
    int? dayIndex,
    String? name,
    String? prompt,
    String? note,
    String? emoji,
  }) {
    return SkillItem(
      id: id,
      dayIndex: dayIndex ?? this.dayIndex,
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      note: note ?? this.note,
      emoji: emoji ?? this.emoji,
    );
  }

  factory SkillItem.fromMap(Map<String, dynamic> map) {
    return SkillItem(
      id: map['id'] as String,
      dayIndex: (map['day_index'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? 'Untitled Skill',
      prompt: map['prompt'] as String? ?? 'What did I learn today?',
      note: map['note'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🧠',
    );
  }
}

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  static const _dayNames = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  final Map<String, TextEditingController> _noteControllers = {};
  final Map<String, Timer> _saveDebounceTimers = {};

  List<SkillItem> _skills = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchSkills(showLoader: true);
    AppRefreshBus.notifier.addListener(_handleGlobalRefresh);
  }

  @override
  void dispose() {
    AppRefreshBus.notifier.removeListener(_handleGlobalRefresh);
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    for (final t in _saveDebounceTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _handleGlobalRefresh() {
    if (!mounted) return;
    _fetchSkills();
  }

  int _todayDayIndex() {
    const dartToApp = {6: 0, 7: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6};
    return dartToApp[DateTime.now().weekday] ?? 0;
  }

  TextEditingController _controllerForSkill(SkillItem skill) {
    final existing = _noteControllers[skill.id];
    if (existing != null) {
      if (existing.text != skill.note) {
        existing.text = skill.note;
      }
      return existing;
    }

    final created = TextEditingController(text: skill.note);
    _noteControllers[skill.id] = created;
    return created;
  }

  Future<void> _fetchSkills({bool showLoader = false}) async {
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
      final skills = OfflineSyncService.instance
          .getSkillsLocal()
          .map(SkillItem.fromMap)
          .toList()
        ..sort((a, b) {
          final day = a.dayIndex.compareTo(b.dayIndex);
          if (day != 0) return day;
          return a.id.compareTo(b.id);
        });

      final activeIds = skills.map((s) => s.id).toSet();
      final disposedIds = _noteControllers.keys.where((id) => !activeIds.contains(id)).toList();
      for (final id in disposedIds) {
        _noteControllers.remove(id)?.dispose();
        _saveDebounceTimers.remove(id)?.cancel();
      }

      if (!mounted) return;
      setState(() {
        _skills = skills;
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

  Future<void> _saveNote(String skillId, String note) async {
    try {
      await OfflineSyncService.instance.updateSkill(skillId, {
        'note': note,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final idx = _skills.indexWhere((s) => s.id == skillId);
      if (idx >= 0 && mounted) {
        setState(() {
          _skills[idx] = _skills[idx].copyWith(note: note);
        });
      }
      unawaited(OfflineSyncService.instance.syncNow());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save note: $e'),
          backgroundColor: context.themeColors.neonRed,
        ),
      );
    }
  }

  void _onNoteChanged(String skillId, String value) {
    _saveDebounceTimers[skillId]?.cancel();
    _saveDebounceTimers[skillId] = Timer(const Duration(milliseconds: 450), () {
      _saveNote(skillId, value);
    });
  }

  Future<void> _openSkillForm({SkillItem? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final promptController = TextEditingController(text: existing?.prompt ?? 'What did I learn today?');
    final emojiController = TextEditingController(text: existing?.emoji ?? '🧠');
    int selectedDayIndex = existing?.dayIndex ?? _todayDayIndex();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: context.themeColors.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(top: BorderSide(color: context.themeColors.borderSubtle)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        existing == null ? 'ADD NEW SKILL' : 'EDIT SKILL',
                        style: GoogleFonts.orbitron(
                          color: context.themeColors.electricBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        context,
                        controller: nameController,
                        label: 'Skill Name',
                        hint: 'e.g. Flutter Animations',
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        context,
                        controller: promptController,
                        label: 'Daily Prompt',
                        hint: 'What did I build today?',
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        context,
                        controller: emojiController,
                        label: 'Icon Emoji',
                        hint: '🧠',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Day',
                        style: GoogleFonts.shareTechMono(
                          color: context.themeColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: selectedDayIndex,
                        dropdownColor: context.themeColors.bgCard,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.themeColors.bgCardLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.themeColors.borderSubtle),
                          ),
                        ),
                        items: List.generate(
                          _dayNames.length,
                          (i) => DropdownMenuItem<int>(
                            value: i,
                            child: Text(
                              _dayNames[i],
                              style: GoogleFonts.shareTechMono(color: context.themeColors.textPrimary),
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          if (v == null) return;
                          setModalState(() => selectedDayIndex = v);
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          if (existing != null)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop({'delete': true}),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.themeColors.neonRed),
                                ),
                                child: Text(
                                  'DELETE',
                                  style: GoogleFonts.orbitron(
                                    color: context.themeColors.neonRed,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          if (existing != null) const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Skill name is required'),
                                      backgroundColor: context.themeColors.neonRed,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.of(context).pop({
                                  'name': name,
                                  'prompt': promptController.text.trim().isEmpty
                                      ? 'What did I learn today?'
                                      : promptController.text.trim(),
                                  'emoji': emojiController.text.trim().isEmpty ? '🧠' : emojiController.text.trim(),
                                  'day_index': selectedDayIndex,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.themeColors.neonGreen,
                                foregroundColor: Colors.black,
                              ),
                              child: Text(
                                existing == null ? 'ADD SKILL' : 'SAVE CHANGES',
                                style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    promptController.dispose();
    emojiController.dispose();

    if (result == null) return;

    if (result['delete'] == true && existing != null) {
      await _deleteSkill(existing.id);
      return;
    }

    if (existing == null) {
      await _createSkill(result);
    } else {
      await _updateSkill(existing.id, result);
    }
  }

  Future<void> _createSkill(Map<String, dynamic> data) async {
    try {
      await OfflineSyncService.instance.upsertSkill({
        'name': data['name'],
        'prompt': data['prompt'],
        'emoji': data['emoji'],
        'day_index': data['day_index'],
        'note': '',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      unawaited(OfflineSyncService.instance.syncNow());
      await _fetchSkills();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add skill: $e'),
          backgroundColor: context.themeColors.neonRed,
        ),
      );
    }
  }

  Future<void> _updateSkill(String skillId, Map<String, dynamic> data) async {
    try {
      await OfflineSyncService.instance.updateSkill(skillId, {
        'name': data['name'],
        'prompt': data['prompt'],
        'emoji': data['emoji'],
        'day_index': data['day_index'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      unawaited(OfflineSyncService.instance.syncNow());
      await _fetchSkills();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update skill: $e'),
          backgroundColor: context.themeColors.neonRed,
        ),
      );
    }
  }

  Future<void> _deleteSkill(String skillId) async {
    try {
      await OfflineSyncService.instance.deleteSkill(skillId);
      _noteControllers.remove(skillId)?.dispose();
      _saveDebounceTimers.remove(skillId)?.cancel();
      unawaited(OfflineSyncService.instance.syncNow());
      await _fetchSkills();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete skill: $e'),
          backgroundColor: context.themeColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = _todayDayIndex();

    return Scaffold(
      backgroundColor: context.themeColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SKILLS MATRIX',
          style: GoogleFonts.orbitron(
            color: context.themeColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'skills_fab',
        onPressed: () => _openSkillForm(),
        backgroundColor: context.themeColors.gold,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: (_isLoading && !_hasLoadedOnce)
          ? Center(child: CircularProgressIndicator(color: context.themeColors.gold))
          : _loadError != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchSkills,
                  child: _skills.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            const SizedBox(height: 120),
                            _buildEmptyState(),
                            const SizedBox(height: 120),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20).copyWith(bottom: 100),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: _skills.length,
                          itemBuilder: (context, index) {
                            final skill = _skills[index];
                            final isToday = skill.dayIndex == todayIndex;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildSkillCard(skill, index, isToday),
                            );
                          },
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
              'FAILED TO LOAD SKILLS',
              style: GoogleFonts.orbitron(
                color: context.themeColors.neonRed,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(
                color: context.themeColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _fetchSkills,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_alt_outlined, color: context.themeColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              'NO SKILLS YET',
              style: GoogleFonts.orbitron(
                color: context.themeColors.textMuted,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + to add your first skill.',
              style: GoogleFonts.shareTechMono(
                color: context.themeColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillCard(SkillItem skill, int index, bool isToday) {
    final dayName = _dayNames[skill.dayIndex.clamp(0, 6)];
    final noteController = _controllerForSkill(skill);

    return GlowCard(
      glowing: isToday,
      glowColor: isToday ? context.themeColors.gold : context.themeColors.electricBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        color: context.themeColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.themeColors.gold.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    dayName.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: isToday ? context.themeColors.gold : context.themeColors.textSecondary,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _openSkillForm(existing: skill),
                child: Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: context.themeColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(skill.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skill.name,
                  style: GoogleFonts.shareTechMono(
                    color: context.themeColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.themeColors.bgCardLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.themeColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.prompt,
                  style: GoogleFonts.shareTechMono(
                    color: context.themeColors.textMuted,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextField(
                  controller: noteController,
                  style: GoogleFonts.shareTechMono(
                    color: context.themeColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tap to log your progress...',
                    hintStyle: GoogleFonts.shareTechMono(
                      color: context.themeColors.textMuted.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  onChanged: (val) => _onNoteChanged(skill.id, val),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: context.themeColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.shareTechMono(color: context.themeColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.shareTechMono(
              color: context.themeColors.textMuted.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: context.themeColors.bgCardLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.themeColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.themeColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.themeColors.electricBlue),
            ),
          ),
        ),
      ],
    );
  }
}
