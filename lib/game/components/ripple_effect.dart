import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Expanding ripple effect component
class RippleEffect extends PositionComponent with HasPaint {
  double _opacity = 1.0;
  double _elapsed = 0.0;
  static const double _lifetime = 1.0;
  final Color color;

  RippleEffect({required Vector2 position, this.color = Colors.cyan})
      : super(position: position, size: Vector2.all(0), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Expand effect
    add(
      ScaleEffect.to(
        Vector2.all(100),
        EffectController(duration: _lifetime, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _opacity = 1.0 - (_elapsed / _lifetime);
    
    if (_elapsed >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Clamp opacity to valid range [0.0, 1.0]
    final clampedOpacity = (0.6 * _opacity).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withOpacity(clampedOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, size.x / 2, paint);
  }
}
