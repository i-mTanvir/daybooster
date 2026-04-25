import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = Supabase.instance.client.auth.currentUser;

  void _cycleTheme(AppThemeType themeType) {
    HapticFeedback.lightImpact();
    switch (themeType) {
      case AppThemeType.dark:
        AppTheme.themeNotifier.value = AppThemeType.cream;
        break;
      case AppThemeType.cream:
        AppTheme.themeNotifier.value = AppThemeType.lime;
        break;
      case AppThemeType.lime:
        AppTheme.themeNotifier.value = AppThemeType.dark;
        break;
    }
  }

  ({IconData icon, Color color}) _themeVisual(AppThemeType themeType, AppThemeColors colors) {
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
    HapticFeedback.heavyImpact();
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final meta = user?.userMetadata ?? {};
    final name = meta['name'] ?? 'UNKNOWN ARCHITECT';
    final age = meta['age']?.toString() ?? 'N/A';
    final phone = meta['phone_number'] ?? 'N/A';
    final email = user?.email ?? 'N/A';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IDENTITY CARD
              GlowCard(
                glowColor: colors.neonPurple.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Avatar Placeholder
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.bg,
                          border: Border.all(color: colors.neonPurple, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: colors.neonPurple.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(Icons.person, size: 50, color: colors.electricBlue),
                      ).animate().shimmer(duration: 2.seconds, color: colors.neonPurple),
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
                      // Meta Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMetaItem('AGE', age, colors),
                          Container(width: 1, height: 40, color: colors.borderSubtle),
                          _buildMetaItem('PHONE', phone, colors),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 40),

              // SYSTEM SETTINGS
              Text(
                'SYSTEM PROTOCOLS',
                style: GoogleFonts.shareTechMono(
                  color: colors.electricBlue,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              
              _buildSettingTile(
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                subtitle: 'Enable mechanical tactile responses',
                colors: colors,
                hasSwitch: true,
                initialValue: true,
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
              
              _buildSettingTile(
                icon: Icons.sync,
                title: 'Cloud Synchronization',
                subtitle: 'Push local data to central nexus',
                colors: colors,
                hasSwitch: true,
                initialValue: true,
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
              
              _buildSettingTile(
                icon: Icons.security,
                title: 'Biometric Lock',
                subtitle: 'Require FaceID/TouchID for access',
                colors: colors,
                hasSwitch: true,
                initialValue: false,
              ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),

              const SizedBox(height: 60),

              // LOGOUT BUTTON
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
    );
  }

  Widget _buildMetaItem(String label, String value, AppThemeColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
    bool initialValue = false,
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
                value: initialValue,
                onChanged: (val) {},
                activeThumbColor: colors.neonPurple,
                activeTrackColor: colors.neonPurple.withValues(alpha: 0.3),
              )
            : Icon(Icons.chevron_right, color: colors.textMuted),
      ),
    );
  }
}
