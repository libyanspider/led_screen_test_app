import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Visual component that draws the screen separation line and labels
class ScreenSeparator extends PositionComponent {
  final double separatorY;
  final double screenWidth;
  
  ScreenSeparator({
    required this.separatorY,
    required this.screenWidth,
  }) : super(
          position: Vector2(0, separatorY),
          size: Vector2(screenWidth, 0),
        );

  @override
  void render(Canvas canvas) {
    // Draw the separator line
    final linePaint = Paint()
      ..color = Colors.amber.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw dashed line
    const dashWidth = 20.0;
    const dashSpace = 10.0;
    double startX = 0;

    while (startX < screenWidth) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        linePaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw labels with background
    _drawLabel(canvas, 'TOP SCREEN', Offset(screenWidth / 2, -40));
    _drawLabel(canvas, 'BOTTOM SCREEN (Touch Area)', Offset(screenWidth / 2, 40));
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Draw semi-transparent background
    final bgRect = Rect.fromCenter(
      center: offset,
      width: textPainter.width + 20,
      height: textPainter.height + 10,
    );
    
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );
    
    // Draw border
    final borderPaint = Paint()
      ..color = Colors.amber.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      borderPaint,
    );
    
    // Draw text
    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }
}
