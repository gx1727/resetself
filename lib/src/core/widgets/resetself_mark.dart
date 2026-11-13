import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 品牌标记「归位环」。
///
/// 开口圆环走到顶部收住（缺口在右上 = 走出循环），环的终点落一颗实心点
/// （回到原点，从这里重新开始）。几何与 design/logo/generate_logo.py 的
/// 96x96 矢量源一一对应，任意尺寸都保持锐利。
class ResetSelfMark extends StatelessWidget {
  const ResetSelfMark({
    super.key,
    this.size = 24,
    this.ringColor = const Color(0xFF819B8E),
    this.dotColor = const Color(0xFF2D2D2D),
  });

  final double size;
  final Color ringColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ResetSelfMarkPainter(ringColor: ringColor, dotColor: dotColor),
      ),
    );
  }
}

class _ResetSelfMarkPainter extends CustomPainter {
  const _ResetSelfMarkPainter({required this.ringColor, required this.dotColor});

  static const double _grid = 96;
  static const double _ringRadius = 30;
  static const double _ringWidth = 6.4;
  static const double _gapStart = -30; // 缺口右边界（正上方偏右）
  static const double _sweep = 298; // 自缺口右边界顺时针画过的角度
  static const double _legDotRadius = 6.5;

  final Color ringColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / _grid;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = _ringRadius * unit;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _gapStart * math.pi / 180,
      _sweep * math.pi / 180,
      false,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth * unit
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      center + Offset.fromDirection((_gapStart + _sweep) * math.pi / 180, radius),
      _legDotRadius * unit,
      Paint()..color = dotColor,
    );
  }

  @override
  bool shouldRepaint(_ResetSelfMarkPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor || oldDelegate.dotColor != dotColor;
}
