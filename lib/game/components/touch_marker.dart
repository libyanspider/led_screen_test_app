import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Touch marker that pulses and fades
class TouchMarker extends PositionComponent with HasPaint {
  double _opacity = 1.0;
  double _elapsed = 0.0;
  static const double _pulseDuration = 0.3;
  static const double _fadeStart = 0.2;
  static const double _lifetime = 0.8;
  double _scale = 1.0;
  final Color color;

  TouchMarker({required Vector2 position, this.color = Colors.cyan})
      : super(
          position: position,
          size: Vector2.all(30),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    
    // Pulse effect
    if (_elapsed < _pulseDuration * 2) {
      final progress = _elapsed / _pulseDuration;
      if (progress < 1.0) {
        _scale = 1.0 + 0.5 * progress;
      } else {
        _scale = 1.5 - 0.5 * (progress - 1.0);
      }
    }
    
    // Fade out
    if (_elapsed >= _fadeStart) {
      _opacity = 1.0 - ((_elapsed - _fadeStart) / (_lifetime - _fadeStart));
    }
    
    if (_elapsed >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Clamp opacity to valid range [0.0, 1.0]
    final clampedOpacity = _opacity.clamp(0.0, 1.0);
    
    canvas.save();
    canvas.scale(_scale);
    
    // Outer glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * clampedOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, size.x / 2, glowPaint);
    
    // Inner circle
    final paint = Paint()
      ..color = Colors.white.withOpacity(clampedOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size.x / 3, paint);

    // Outer ring
    final ringPaint = Paint()
      ..color = color.withOpacity(clampedOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, size.x / 2, ringPaint);
    
    canvas.restore();
  }
}
