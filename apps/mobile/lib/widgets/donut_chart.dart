import 'dart:math' as math;

import 'package:flutter/material.dart';

class DonutSlice {
  DonutSlice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

/// A clean donut chart with a centered label. Pure CustomPaint (no deps).
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 160,
    this.stroke = 26,
    this.centerTop,
    this.centerBottom,
  });

  final List<DonutSlice> slices;
  final double size;
  final double stroke;
  final String? centerTop;
  final String? centerBottom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(slices, stroke),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerTop != null)
                Text(centerTop!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              if (centerBottom != null)
                Text(centerBottom!,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.stroke);
  final List<DonutSlice> slices;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final total = slices.fold<double>(0, (s, e) => s + e.value);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFEEF1F6);
    canvas.drawCircle(center, radius, bg);

    if (total <= 0) return;
    var start = -math.pi / 2;
    const gap = 0.04;
    for (final s in slices) {
      final sweep = (s.value / total) * (2 * math.pi) - gap;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = s.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices != slices || old.stroke != stroke;
}
