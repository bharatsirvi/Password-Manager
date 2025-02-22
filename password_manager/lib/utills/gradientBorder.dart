import 'package:flutter/material.dart';

class GradientOutlineInputBorder extends OutlineInputBorder {
  final Gradient gradient;

  GradientOutlineInputBorder({
    required this.gradient,
    BorderRadius borderRadius = BorderRadius.zero,
    BorderSide borderSide = BorderSide.none,
  }) : super(borderRadius: borderRadius, borderSide: borderSide);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double? gapExtent,
    double? gapPercentage,
    TextDirection? textDirection,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderSide.width;

    final outer = borderRadius.toRRect(rect);
    final inner = borderRadius.toRRect(rect.deflate(borderSide.width));

    canvas.drawDRRect(outer, inner, paint);
  }
}
