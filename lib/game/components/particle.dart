import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Individual particle that moves outward and fades
class Particle extends PositionComponent {
  final double startAngle;
  final VoidCallback onComplete;
  final Color color;
  static const double speed = 150.0;
  static const double lifetime = 0.8;
  double elapsed = 0;

  Particle({
    required this.startAngle, 
    required this.onComplete,
    this.color = Colors.cyan,
  }) : super(size: Vector2.all(6), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    
    elapsed += dt;
    if (elapsed >= lifetime) {
      removeFromParent();
      return;
    }

    // Move outward
    position.x += speed * dt * (1 - elapsed / lifetime) * cos(startAngle);
    position.y += speed * dt * (1 - elapsed / lifetime) * sin(startAngle);
  }

  @override
  void render(Canvas canvas) {
    // Clamp opacity to valid range [0.0, 1.0]
    final opacity = (1 - (elapsed / lifetime)).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, size.x / 2, paint);
  }
}
