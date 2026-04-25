import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _cycleTheme(AppThemeType themeType) {
    HapticFeedback.lightImpact();
    AppTheme.setTheme(AppTheme.nextTheme(themeType));
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // AppRouter will automatically detect the auth change and navigate to MainShell
    } catch (e) {
      final raw = e.toString();
      final msg = raw.contains('Failed host lookup') || raw.contains('SocketException')
          ? 'No internet/DNS connection. Please enable data or Wi-Fi and try again.'
          : raw;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: context.themeColors.neonRed,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: ValueListenableBuilder<AppThemeType>(
                valueListenable: AppTheme.themeNotifier,
                builder: (context, themeType, _) {
                  final visual = _themeVisual(themeType, colors);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, right: 20),
                    child: IconButton(
                      onPressed: () => _cycleTheme(themeType),
                      icon: Icon(visual.icon, color: visual.color, size: 22),
                      tooltip: 'Toggle Theme',
                    ),
                  );
                },
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Icon(Icons.bolt, size: 80, color: colors.electricBlue)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .shimmer(duration: 2.seconds, color: colors.neonPurple),
                const SizedBox(height: 16),
                Text(
                  'DAYBOOSTER',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    color: colors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  'INITIALIZE SESSION',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.shareTechMono(
                    color: colors.electricBlue,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 60),
                _buildTextField(
                  controller: _emailController,
                  label: 'EMAIL',
                  icon: Icons.email_outlined,
                  colors: colors,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: 'PASSWORD',
                  icon: Icons.lock_outline,
                  colors: colors,
                  obscureText: true,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.electricBlue,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: colors.electricBlue.withValues(alpha: 0.5),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            'ACCESS SYSTEM',
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  child: Text(
                    'NEW ARCHITECT? FORGE PROFILE',
                    style: GoogleFonts.shareTechMono(
                      color: colors.textMuted,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                  ],
                ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
              ),
            ),
          ],
          ),
        ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppThemeColors colors,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.shareTechMono(color: colors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.orbitron(color: colors.textMuted, fontSize: 12, letterSpacing: 1.5),
        prefixIcon: Icon(icon, color: colors.electricBlue),
        filled: true,
        fillColor: colors.bgCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.electricBlue, width: 2),
        ),
      ),
    );
  }
}
