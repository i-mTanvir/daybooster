import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/haptics_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _avatarBucket = 'avatars';

  User? _user;
  bool _uploadingAvatar = false;
  String? _avatarUrl;
  bool _showOfflineBanner = false;
  Timer? _networkTimer;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    _avatarUrl = _user?.userMetadata?['avatar_url'] as String?;
    _checkOnlineStatus();
    _networkTimer = Timer.periodic(const Duration(seconds: 18), (_) {
      _checkOnlineStatus();
    });
  }

  @override
  void dispose() {
    _networkTimer?.cancel();
    super.dispose();
  }

  void _cycleTheme(AppThemeType themeType) {
    HapticsService.lightImpact();
    AppTheme.setTheme(AppTheme.nextTheme(themeType));
  }

  ({IconData icon, Color color}) _themeVisual(
    AppThemeType themeType,
    AppThemeColors colors,
  ) {
    switch (themeType) {
      case AppThemeType.dark:
        return (icon: Icons.light_mode_rounded, color: colors.gold);
      case AppThemeType.cream:
        return (icon: Icons.eco_rounded, color: colors.neonGreen);
      case AppThemeType.lime:
        return (icon: Icons.dark_mode_rounded, color: colors.neonPurple);
    }
  }

  Future<void> _logout() async {
    HapticsService.heavyImpact();
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar || _user == null) return;
    HapticsService.selectionClick();

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      final path = '${_user!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage.from(_avatarBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = Supabase.instance.client.storage
          .from(_avatarBucket)
          .getPublicUrl(path);

      final updatedMeta = Map<String, dynamic>.from(_user?.userMetadata ?? {});
      updatedMeta['avatar_url'] = publicUrl;
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: updatedMeta),
      );

      try {
        await Supabase.instance.client.from('profiles').upsert({
          'id': _user!.id,
          'avatar_url': publicUrl,
        });
      } catch (_) {
        // Avatar may still work from user metadata if profile column is not present.
      }

      if (!mounted) return;
      setState(() {
        _avatarUrl = publicUrl;
        _user = Supabase.instance.client.auth.currentUser;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile image updated'),
          backgroundColor: context.themeColors.neonGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: context.themeColors.neonRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _checkOnlineStatus() async {
    if (!mounted || _user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', _user!.id)
          .limit(1)
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      if (_showOfflineBanner) {
        setState(() => _showOfflineBanner = false);
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isNetworkIssue = msg.contains('socketexception') ||
          msg.contains('failed host lookup') ||
          msg.contains('network') ||
          msg.contains('timed out') ||
          msg.contains('clientexception');
      if (!mounted) return;
      if (isNetworkIssue && !_showOfflineBanner) {
        setState(() => _showOfflineBanner = true);
      }
      if (!isNetworkIssue && _showOfflineBanner) {
        setState(() => _showOfflineBanner = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final meta = _user?.userMetadata ?? {};
    final name = meta['name'] ?? 'UNKNOWN ARCHITECT';
    final age = meta['age']?.toString() ?? 'N/A';
    final phone = meta['phone_number'] ?? 'N/A';
    final email = _user?.email ?? 'N/A';

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          ValueListenableBuilder<AppThemeType>(
            valueListenable: AppTheme.themeNotifier,
            builder: (context, themeType, _) {
              final visual = _themeVisual(themeType, colors);
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: () => _cycleTheme(themeType),
                  icon: Icon(visual.icon, color: visual.color, size: 22),
                  tooltip: 'Toggle Theme',
                ),
              );
            },
          ),
        ],
        title: Text(
          'ARCHITECT HUB',
          style: GoogleFonts.orbitron(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_showOfflineBanner)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.neonYellow.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.neonYellow.withValues(alpha: 0.55)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: colors.neonYellow, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OFFLINE MODE',
                        style: GoogleFonts.orbitron(
                          color: colors.neonYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              GlowCard(
                glowColor: colors.neonPurple.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.bg,
                              border: Border.all(
                                color: colors.neonPurple,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.neonPurple.withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? Image.network(
                                      _avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.person, size: 54, color: colors.electricBlue),
                                    )
                                  : Icon(Icons.person, size: 54, color: colors.electricBlue),
                            ),
                          ).animate().shimmer(duration: 2.seconds, color: colors.neonPurple),
                          Positioned(
                            right: -4,
                            bottom: -2,
                            child: InkWell(
                              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colors.electricBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.bg, width: 2),
                                ),
                                child: _uploadingAvatar
                                    ? Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colors.bg,
                                        ),
                                      )
                                    : Icon(
                                        Icons.image_outlined,
                                        size: 18,
                                        color: colors.bg,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name.toString().toUpperCase(),
                        style: GoogleFonts.orbitron(
                          color: colors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.shareTechMono(
                          color: colors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 330;
                          if (isCompact) {
                            return Column(
                              children: [
                                _buildMetaItem('AGE', age, colors),
                                const SizedBox(height: 14),
                                Container(
                                  width: 140,
                                  height: 1,
                                  color: colors.borderSubtle,
                                ),
                                const SizedBox(height: 14),
                                _buildMetaItem('PHONE', phone, colors),
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMetaItem('AGE', age, colors),
                              Container(width: 1, height: 40, color: colors.borderSubtle),
                              _buildMetaItem('PHONE', phone, colors),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 40),
              Text(
                'SYSTEM PROTOCOLS',
                style: GoogleFonts.shareTechMono(
                  color: colors.electricBlue,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: HapticsService.enabledNotifier,
                builder: (context, enabled, _) {
                  return _buildSettingTile(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    subtitle: 'Enable mechanical tactile responses',
                    colors: colors,
                    hasSwitch: true,
                    switchValue: enabled,
                    onSwitchChanged: (val) async {
                      await HapticsService.setEnabled(val);
                      if (val) HapticsService.lightImpact();
                    },
                  );
                },
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
              _buildSettingTile(
                icon: Icons.sync,
                title: 'Cloud Synchronization',
                subtitle: 'Auto sync managed by system',
                colors: colors,
                hasSwitch: false,
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
              const SizedBox(height: 60),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.power_settings_new),
                  label: Text(
                    'TERMINATE SESSION',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.bgCardLight,
                    foregroundColor: colors.neonRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colors.neonRed.withValues(alpha: 0.5)),
                    ),
                    elevation: 0,
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, AppThemeColors colors) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: GoogleFonts.orbitron(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: colors.textMuted,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppThemeColors colors,
    bool hasSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListTile(
        leading: Icon(icon, color: colors.electricBlue),
        title: Text(
          title,
          style: GoogleFonts.orbitron(color: colors.textPrimary, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.shareTechMono(color: colors.textSecondary, fontSize: 11),
        ),
        trailing: hasSwitch
            ? Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeThumbColor: colors.neonPurple,
                activeTrackColor: colors.neonPurple.withValues(alpha: 0.3),
              )
            : Icon(Icons.chevron_right, color: colors.textMuted),
      ),
    );
  }
}
