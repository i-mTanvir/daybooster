import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GlowCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool glowing;

  const GlowCard({
    super.key,
    required this.child,
    this.glowColor = AppColors.electricBlue,
    this.padding,
    this.borderRadius = 16,
    this.glowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgCardLight,
            AppColors.bgCard,
          ],
        ),
        border: Border.all(
          color: glowColor.withValues(alpha: glowing ? 0.45 : 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: glowing ? 0.25 : 0.10),
            blurRadius: glowing ? 20 : 10,
            spreadRadius: glowing ? 2 : 0,
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

class GlowText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;
  final double glowRadius;

  const GlowText({
    super.key,
    required this.text,
    this.style,
    this.glowColor = AppColors.electricBlue,
    this.glowRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: style?.copyWith(
            color: Colors.transparent,
            shadows: [
              Shadow(
                color: glowColor.withValues(alpha: 0.7),
                blurRadius: glowRadius * 2,
              ),
            ],
          ),
        ),
        Text(text, style: style),
      ],
    );
  }
}
