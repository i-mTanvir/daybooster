import 'dart:math' as math;
import 'package:flutter/material.dart';

class CyberpunkGridPainter extends CustomPainter {
  final double animValue;
  CyberpunkGridPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    // Vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Animated pulse circles
    final pulsePaint = Paint()
      ..color = const Color(0xFF9B59FF).withValues(alpha: 0.06 * (1 - animValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width * 0.8, size.height * 0.2);
    canvas.drawCircle(center, 80 + animValue * 60, pulsePaint);
    canvas.drawCircle(center, 120 + animValue * 80, pulsePaint..color = const Color(0xFF00D4FF).withValues(alpha: 0.04 * (1 - animValue)));
  }

  @override
  bool shouldRepaint(CyberpunkGridPainter oldDelegate) => oldDelegate.animValue != animValue;
}

class GlowBorderPainter extends CustomPainter {
  final Color color;
  final double blur;
  final double borderRadius;
  GlowBorderPainter({required this.color, this.blur = 8, this.borderRadius = 16});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, blur)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(GlowBorderPainter old) =>
      old.color != color || old.blur != blur;
}

class ArcScorePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  ArcScorePainter({required this.percentage, required this.color, this.strokeWidth = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFF1E1E35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Progress arc
    final sweepAngle = (percentage.clamp(0, 130) / 130) * math.pi * 1.5;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.6), color],
        startAngle: math.pi * 0.75,
        endAngle: math.pi * 0.75 + sweepAngle,
        tileMode: TileMode.clamp,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi * 0.75,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Glow effect
    if (sweepAngle > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi * 0.75,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ArcScorePainter old) =>
      old.percentage != percentage || old.color != color;
}
