import 'package:flutter/material.dart';

class ProgressCircle extends StatelessWidget {
  const ProgressCircle({
    super.key,
    required this.progress,
    required this.percentageText,
  });

  final double progress;
  final String percentageText;

  @override
  Widget build(BuildContext context) {
    final double clamped =
        progress.isNaN ? 0 : progress.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: CircularProgressIndicator(
              strokeWidth: 14,
              value: clamped == 0 && progress > 0 ? null : clamped,
            ),
          ),
          Text(
            percentageText,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
