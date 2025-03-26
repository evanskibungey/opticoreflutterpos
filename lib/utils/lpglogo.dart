import 'package:flutter/material.dart';

class EldoGasCylinderIcon extends CustomPainter {
  final Color baseColor;
  final Color borderColor;

  EldoGasCylinderIcon({
    this.baseColor = Colors.orange,
    this.borderColor = Colors.orangeAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Main cylinder body
    final cylinderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.2, 
                    size.width * 0.6, size.height * 0.6),
      const Radius.circular(10)
    );
    canvas.drawRRect(cylinderRect, paint);
    canvas.drawRRect(cylinderRect, borderPaint);

    // Top valve
    final valveRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.4, size.height * 0.1, 
                    size.width * 0.2, size.height * 0.15),
      const Radius.circular(5)
    );
    canvas.drawRRect(valveRect, paint);
    canvas.drawRRect(valveRect, borderPaint);

    // Bottom stand
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.8, 
                    size.width * 0.4, size.height * 0.1),
      const Radius.circular(5)
    );
    canvas.drawRRect(baseRect, paint);
    canvas.drawRRect(baseRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}