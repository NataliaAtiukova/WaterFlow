import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedProgressLiquid extends StatelessWidget {
  const AnimatedProgressLiquid({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      height: 220,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _LiquidPainter(value: clamped),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(clamped * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('прогресс', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blueAccent.withValues(alpha: 0.9),
          Colors.cyanAccent.withValues(alpha: 0.7),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    const waveHeight = 8.0;
    final baseHeight = size.height * (1 - value);
    final path = Path()..moveTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      final y = baseHeight + waveHeight * sin((x / size.width) * 2 * pi);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final ellipse = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(ellipse));
    canvas.drawPath(path, paint);
    canvas.restore();
    canvas.drawOval(ellipse, outline);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
