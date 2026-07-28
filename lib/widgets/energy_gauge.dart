import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A circular progress gauge showing a 0-10 energy score, styled to
/// match the app's warm orange/brown theme. Used on the Home feed's
/// redesigned greeting card.
class EnergyGauge extends StatelessWidget {
  final double score; // 0-10
  final double size;
  const EnergyGauge({super.key, required this.score, this.size = 110});

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 10).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(progress: clamped / 10),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clamped % 1 == 0 ? clamped.toInt().toString() : clamped.toStringAsFixed(1),
                style: TextStyle(fontSize: size * 0.26, fontWeight: FontWeight.w700, color: AppTheme.accentOrange),
              ),
              Text('/ 10', style: TextStyle(fontSize: size * 0.11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0.0 - 1.0
  _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const startAngle = -pi / 2;

    final trackPaint = Paint()
      ..color = AppTheme.accentOrangeLight
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * pi,
        colors: const [AppTheme.accentYellow, AppTheme.accentOrange],
        transform: GradientRotation(startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.progress != progress;
}
