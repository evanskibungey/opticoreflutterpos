import 'package:flutter/material.dart';

class LPGCylinderPainter extends CustomPainter {
  final Color baseColor;
  final Color borderColor;
  final bool showShadow;
  final Color? glowColor;

  LPGCylinderPainter({
    this.baseColor = Colors.white,
    this.borderColor = Colors.white70,
    this.showShadow = false,
    this.glowColor,
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
      
    // Add shadow if enabled
    if (showShadow) {
      // Shadow for main cylinder
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
        
      final shadowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.2 + 5, // Offset shadow to right
          size.height * 0.2 + 10, // Offset shadow down
          size.width * 0.6,
          size.height * 0.6
        ),
        const Radius.circular(10)
      );
      canvas.drawRRect(shadowRect, shadowPaint);
      
      // Optional glow effect
      if (glowColor != null) {
        final glowPaint = Paint()
          ..color = glowColor!.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
          
        final glowRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.15, 
            size.height * 0.15,
            size.width * 0.7,
            size.height * 0.7
          ),
          const Radius.circular(15)
        );
        canvas.drawRRect(glowRect, glowPaint);
      }
    }

    // Main cylinder body
    final cylinderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.2, 
                    size.width * 0.6, size.height * 0.6),
      const Radius.circular(10)
    );
    canvas.drawRRect(cylinderRect, paint);
    
    // Add cylinder details if it's large enough
    if (size.width > 100) {
      // Gas level indicator
      final levelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25, 
          size.height * 0.3, 
          size.width * 0.5, 
          size.height * 0.4
        ),
        const Radius.circular(8)
      );
      
      // Draw slightly darker area for level indicator
      final levelPaint = Paint()
        ..color = baseColor.withOpacity(0.7)
        ..style = PaintingStyle.fill;
        
      canvas.drawRRect(levelRect, levelPaint);
      
      // Horizontal lines for cylinder texture
      final linePaint = Paint()
        ..color = borderColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
        
      for (int i = 1; i <= 3; i++) {
        final y = size.height * (0.3 + (i * 0.1));
        canvas.drawLine(
          Offset(size.width * 0.25, y),
          Offset(size.width * 0.75, y),
          linePaint
        );
      }
    }
    
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
    
    // Add valve detail on top if large enough
    if (size.width > 100) {
      final valveTopPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.1),
        size.width * 0.05,
        valveTopPaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is LPGCylinderPainter) {
      return oldDelegate.baseColor != baseColor ||
             oldDelegate.borderColor != borderColor ||
             oldDelegate.showShadow != showShadow ||
             oldDelegate.glowColor != glowColor;
    }
    return true;
  }
}