import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/user_storage.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/painters.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _loading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    await UserStorage.setArchitectName(name);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeColors.bg,
      body: Stack(
        children: [
          // Grid background
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => CustomPaint(
              painter: CyberpunkGridPainter(_pulseController.value),
              size: Size.infinite,
            ),
          ),

          // Purple glow
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.themeColors.neonPurple.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Blue glow
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
                    context.themeColors.electricBlue.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / Title
                  Center(
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Text(
                            '⚡',
                            style: TextStyle(
                              fontSize: 64,
                              shadows: [
                                Shadow(
                                  color: context.themeColors.electricBlue.withValues(alpha: 0.5 + 0.3 * _pulseController.value),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                          ),
                        ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 16),

                        Text(
                          'DAYBOOSTER',
                          style: GoogleFonts.orbitron(
                            color: context.themeColors.electricBlue,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 8),

                        Text(
                          'THE ARCHITECT PROTOCOL',
                          style: GoogleFonts.orbitron(
                            color: context.themeColors.neonPurple,
                            fontSize: 11,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Input card
                  GlowCard(
                    glowColor: context.themeColors.electricBlue,
                    glowing: true,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARCHITECT IDENTIFICATION',
                          style: GoogleFonts.orbitron(
                            color: context.themeColors.textSecondary,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your name to begin your legacy.',
                          style: GoogleFonts.shareTechMono(
                            color: context.themeColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _controller,
                          style: GoogleFonts.orbitron(
                            color: context.themeColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Your name...',
                            hintStyle: GoogleFonts.orbitron(
                              color: context.themeColors.textMuted,
                              fontSize: 16,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: context.themeColors.borderSubtle),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: context.themeColors.electricBlue, width: 2),
                            ),
                            prefixText: 'ARCHITECT ',
                            prefixStyle: GoogleFonts.orbitron(
                              color: context.themeColors.electricBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _loading ? null : _submit,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, __) => Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      context.themeColors.electricBlue,
                                      context.themeColors.neonPurple,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.themeColors.electricBlue.withValues(alpha: 0.3 + 0.2 * _pulseController.value),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'INITIALIZE SYSTEM ⚡',
                                          style: GoogleFonts.orbitron(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms, duration: 800.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      '"You are not building a routine.\nYou are building a legacy."',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.shareTechMono(
                        color: context.themeColors.textMuted,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ).animate().fadeIn(delay: 1200.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

