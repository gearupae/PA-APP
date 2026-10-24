import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Radial mind map: the note title in the centre with grouped leaf nodes
/// (topics / action items / key points) arranged around it.
class MindMapView extends StatelessWidget {
  const MindMapView({super.key, required this.root});

  final MapNode root;

  static const _groupColors = <String, Color>{
    'Topics': AppColors.teal,
    'Action items': AppColors.seed,
    'Key points': AppColors.slate,
  };

  @override
  Widget build(BuildContext context) {
    // Flatten leaves with a colour per group.
    final leaves = <({String label, Color color})>[];
    for (final branch in root.children) {
      final color = _groupColors[branch.label] ?? AppColors.violet;
      for (final child in branch.children) {
        leaves.add((label: child.label, color: color));
      }
    }
    final shown = leaves.take(9).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const h = 360.0;
        final center = Offset(w / 2, h / 2);
        final radius = math.min(w, h) * 0.34;

        final positions = <Offset>[];
        for (var i = 0; i < shown.length; i++) {
          final angle = -math.pi / 2 + i * (2 * math.pi / shown.length);
          positions.add(center +
              Offset(math.cos(angle) * radius, math.sin(angle) * radius));
        }

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              // Connectors.
              CustomPaint(
                size: Size(w, h),
                painter: _Lines(center, positions,
                    shown.map((e) => e.color).toList()),
              ),
              // Leaf nodes.
              for (var i = 0; i < shown.length; i++)
                _node(shown[i].label, shown[i].color, positions[i], w),
              // Centre.
              Positioned(
                left: center.dx - 52,
                top: center.dy - 32,
                child: Container(
                  width: 104,
                  height: 64,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.seed, AppColors.violet]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.seed.withValues(alpha: 0.35),
                          blurRadius: 14),
                    ],
                  ),
                  child: const Text(
                    'Summary',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _node(String label, Color color, Offset pos, double w) {
    const nodeW = 112.0;
    var left = pos.dx - nodeW / 2;
    left = left.clamp(0.0, w - nodeW);
    return Positioned(
      left: left,
      top: pos.dy - 22,
      child: Container(
        width: nodeW,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}

class _Lines extends CustomPainter {
  _Lines(this.center, this.nodes, this.colors);
  final Offset center;
  final List<Offset> nodes;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < nodes.length; i++) {
      final paint = Paint()
        ..color = colors[i].withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(nodes[i].dx, nodes[i].dy);
      canvas.drawPath(path, paint);
      canvas.drawCircle(nodes[i], 3, Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _Lines old) => false;
}
